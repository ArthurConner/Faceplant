//
//  FIleSystem.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/8/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation
import SwiftUI
import ImageIO
import Combine
import Vision


struct FileInfo {
    let path: String
    let date: DateComponents
    let id: UUID = UUID()
    
    var key:String{
        let y = date.year ?? 2000
        let m = date.month ?? 0
        return NSString.path(withComponents: ["\(y)","\(m)",(path as NSString).lastPathComponent])
    }
    
    
    static func dateURL(_ mUrl:URL,isImage:Bool)->DateComponents?{
        
        let fm = FileManager.default
        
        guard let det =  try? fm.attributesOfItem(atPath: mUrl.path), let creationDate  = det[FileAttributeKey.creationDate] as? Date else {
            return nil
        }
        
        if !isImage {
            let calendar = Calendar.current
            return  calendar.dateComponents([.year, .month], from: creationDate)
        }
        
        guard let d = CGImageSourceCreateWithURL(mUrl as CFURL , nil),
            let p = CGImageSourceCopyPropertiesAtIndex(d,0,nil),
            let ex = (p as NSDictionary)["{Exif}"] as? NSDictionary,
            let org =  ex["DateTimeOriginal"] as? NSString
            else   {
                let calendar = Calendar.current
                return  calendar.dateComponents([.year, .month], from: creationDate)
        }
        
        let comp = org.components(separatedBy: ":")
        let year =  Int(comp[0])
        let month =  Int(comp[1])
        
        return  DateComponents(year:year,month: month)
    }
    
    
    
    static func make(path:String,isImage:Bool)->(String,FileInfo)?{
        
        guard let comp = FileInfo.dateURL(URL(fileURLWithPath: path),isImage: isImage) else { return nil}
        
        let r = FileInfo(path: path, date: comp)
        let fname = (path as NSString).lastPathComponent
        
        return ("\(r.key)-->\(fname)",r)
        
    }
}

class ACFileStatus {
    let info: FileInfo
    let key:String
    let didChange = PassthroughSubject<ACFileStatus, Never>()
    
    static let queue = DispatchQueue(label: "image queueue", qos: .background, attributes:.init(), autoreleaseFrequency: .workItem, target: nil)
    
    init?(path:String,isImage:Bool){
        guard let (s,i) = FileInfo.make(path: path, isImage: isImage) else { return nil}
        self.key = s
        self.info = i
    }
    
    func updateMe(){
        DispatchQueue.main.async {
            self.didChange.send(self)
        }
    }
    
    var isKeeper = false{
        didSet {
            updateMe()
        }
    }
    
    var isDuplicateOf:String?{
        didSet {
            updateMe()
        }
    }
    
    var currentRect = CGRect(x: 0, y: 0, width: 80, height: 80){
        didSet {
            updateMe()
        }
    }
    
    func dest(root:String)->String{
        
        let last = isKeeper  ? "Keeper" : "Extra"
        
        let y = info.date.year ?? 2000
        let m = info.date.month ?? 0
        
        let r = NSString.path(withComponents: [root,"\(y)","\(m)",last,(info.path as NSString).lastPathComponent ])
        return r
        
    }
    
    lazy var image = {
        return makeScale(maxDim: ACFileStatus.thumbSize.height)
    }()
    
    
    #if os(OSX)
    static let thumbSize = NSSize(width: 128, height: 128)
    
    func makeScale(maxDim:CGFloat)->NSImage?{
        
        let url = URL(fileURLWithPath: info.path)
        
        print("making thumbnail: \(self.info.path)")
        if let im = NSImage(contentsOf: url){
            let longest = max(im.size.height,im.size.width)
            let scale = maxDim/longest
            let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
            let small = NSImage(size: size)
            let fromRect = NSRect(x: 0, y: 0, width:im.size.width, height: im.size.height)
            small.lockFocus()
            im.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height), from: fromRect, operation: .copy, fraction: 1)
            small.unlockFocus()
            return  small
            
        }
        return nil
    }
    
    
    #else
    static let thumbSize = CGSize(width: 96, height: 96)
    
    
    func makeScale(maxDim:CGFloat)->UIImage?{
        
        if let im = UIImage(contentsOfFile: self.info.path){
            let longest = max(im.size.height,im.size.width)
            let scale = maxDim/longest
            let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            return   renderer.image { (context) in
                im.draw(in: CGRect(origin: .zero, size: size))
            }
            
            
            
        }
        return nil
        //  }
    }
    
    #endif
    
    
    lazy var features:VNFeaturePrintObservation? = {
        let url = URL(fileURLWithPath: info.path)
        print("feature starting: \(info.key)")
        
        
        
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            
            try requestHandler.perform([request])
            print("feature finishing: \(info.key)")
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            print("Vision error: \(error)")
            return nil
        }
        
    }()
    
    
}

extension ACFileStatus : Identifiable{
    public var id:UUID {
        return info.id
    }
}

extension ACFileStatus : BindableObject {
    
}

class ACFileGroup {
    let members:[ACFileStatus]
    init(_ m: [ACFileStatus]) {
        members = m
    }
}

extension ACFileGroup : Identifiable{
    public var id:UUID {
        return members.first?.id ?? UUID()
    }
}

class FileLoader  : BindableObject {
    
    let files:[ACFileStatus]
    var source:String
    let didChange = PassthroughSubject<FileLoader, Never>()
    
    var groups: [ACFileGroup] = [] {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
        }
    }
    
    var theshold:Float = 10.0  {
        didSet {
            self.process()
        }
    }
    
    var selectIndex:Int = -1  {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
            
        }
    }
    
    static func contentsOf(_ path:String, kinds:[String], isImage:Bool = true)->[ACFileStatus]{
        
        let f = FileManager.default
        let list = kinds.map({$0.uppercased()}).map{ $0.replacingOccurrences(of: ".", with: "")}
        
        let keep = Set<String>(list)
        var files: [ACFileStatus] = []
        do {
            for  x in try f.contentsOfDirectory(atPath: path){
                let filekid = (x as NSString).pathExtension.uppercased()
                if keep.contains(filekid),
                    let info = ACFileStatus(path: (path as NSString).appendingPathComponent(x), isImage: isImage){
                    files.append(info)
                }
            }
        } catch {
            print(error)
        }
        
        return files
    }
    
    static func recursive(dirs:[String], kinds:[String], isImage:Bool = true)->[ ACFileStatus]{
        
        let f = FileManager.default
        var files: [ACFileStatus] = []
        
        guard !dirs.isEmpty else {
            return files
        }
        
        var isDir:ObjCBool = true
        for dir in dirs{
            do {
                for x in try f.contentsOfDirectory(atPath: dir){
                    let full =  (dir as NSString).appendingPathComponent(x)
                    if (f.fileExists(atPath: full, isDirectory: &isDir) ){
                        if isDir.boolValue {
                            let adds = FileLoader.recursive(dirs: [full], kinds: kinds, isImage: isImage)
                            for v in adds {
                                files.append(v)
                            }
                        }
                        
                    }
                }
            } catch {
                print(error)
            }
            
            let adds = FileLoader.contentsOf(dir, kinds: kinds, isImage: isImage)
            
            for v in adds {
                files.append(v)
            }
            
        }
        
        return files
        
    }
    
    func process(){
        
        DispatchQueue.global(qos: .background).async {
            guard !self.files.isEmpty else { return }
            
            let f =  self.files.sorted(by: {$0.info.path < $1.info.path})
            
            var ret:[ACFileGroup] = []
            let unknown = f.filter{ $0.features == nil }
            if !unknown.isEmpty {
                ret.append(ACFileGroup(unknown))
            }
            
            let known = f.filter{ $0.features != nil }
            var i = 0
            var current:[ACFileStatus] = []
            while (i < known.count) {
                let check = known[i]
                i += 1
                if let goodExample = current.last{
                    do {
                        var distance = Float(0)
                        try goodExample.features!.computeDistance(&distance, to: check.features!)
                        print("distance from \(goodExample.info.key) to \(check.info.key) is \(distance)")
                        if distance < self.theshold {
                            current.append(check)
                        } else {
                            ret.append(ACFileGroup(current))
                            current = [check]
                        }
                        
                    } catch {
                        ret.append(ACFileGroup(current))
                        current = [check]
                    }
                    
                } else {
                    current.append(check)
                }
                
            }
            
            ret.append(ACFileGroup(current))
            print("we have \(ret.count) groups for \(self.theshold)")
            DispatchQueue.main.async {
                self.groups = ret
            }
        }
    }
    
    private init(path:String, _ f:[ ACFileStatus]){
        source = path
        files = f.sorted{$0.info.key < $1.info.key}
    }
    
    convenience init(_ path:String, kinds:[String], isImage:Bool = true){
        self.init(path:path,FileLoader.contentsOf(path, kinds:kinds, isImage:isImage))
    }
    
    convenience init(recursive path:String, kinds:[String], isImage:Bool = true){
        self.init(path:path,FileLoader.recursive(dirs:[path], kinds:kinds, isImage:isImage))
    }
    
    func exclude(other:FileLoader)->FileLoader{
        let exclude = Set<String>(other.files.map({return $0.info.key}))
        let nextFiles = files.filter({!exclude.contains($0.info.key)})
        return FileLoader(path: self.source, nextFiles)
        
    }

}
