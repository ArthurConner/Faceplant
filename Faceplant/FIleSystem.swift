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
        
        guard
            let comp = FileInfo.dateURL(URL(fileURLWithPath: path),isImage: isImage) else { return nil}
        
        let r = FileInfo(path: path, date: comp)
        let fname = (path as NSString).lastPathComponent
        
        return ("\(r.key)-->\(fname)",r)
        
    }
}

class ACFileStatus   {
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
    
    var image:NSImage?{
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
    
    static let thumbSize = NSSize(width: 128, height: 128)
    
    
    func makeThumb(){
        guard self.image == nil else {return}
        let url = URL(fileURLWithPath: info.path)
        DispatchQueue.main.async {
            print("making thumbnail: \(self.info.path)")
            if let im = NSImage(contentsOf: url){
                let small = NSImage(size: ACFileStatus.thumbSize)
                let fromRect = NSRect(x: 0, y: 0, width:im.size.width, height: im.size.height)
                small.lockFocus()
                im.draw(in: NSRect(x: 0, y: 0, width: ACFileStatus.thumbSize.width, height: ACFileStatus.thumbSize.height), from: fromRect, operation: .copy, fraction: 1)
                small.unlockFocus()
                self.image = small
                print("stopped thumbnail: \(self.info.path)")
            } else {
                print("No image for \(self.info.path)")
            }
        }
    }
    
    lazy var features:VNFeaturePrintObservation? = {
        let url = URL(fileURLWithPath: info.path)
        print("starting: \(info.path)")
        
        
        
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            
            try requestHandler.perform([request])
            print("finishing: \(info.path)")
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
    
    var groups: [ACFileGroup] = [] {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
            
        }
    }
    
    var theshold:Float = 10.0  {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
                self.process()
            }
            
        }
    }
    
    private var files:[ACFileStatus] = []
    
    var source:String
    
    let didChange = PassthroughSubject<FileLoader, Never>()
    
    static func contentsOf(_ path:String, kinds:[String], isImage:Bool = true)->[ACFileStatus]{
        
        let f = FileManager.default
        let list = kinds.map({$0.uppercased()}).map{ $0.replacingOccurrences(of: ".", with: "")}
        
        let keep = Set<String>(list)
        var files: [ACFileStatus] = []
        do {
            for  x in try f.contentsOfDirectory(atPath: path){
                if keep.contains((x as NSString).pathExtension),
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
                
                for  x in try f.contentsOfDirectory(atPath: dir){
                    let full =  (dir as NSString).appendingPathComponent(x)
                    
                    if (f.fileExists(atPath: full, isDirectory: &isDir) ){
                        let adds = FileLoader.recursive(dirs: [dir], kinds: kinds, isImage: isImage)
                        for v in adds {
                            files.append(v)
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
            
            for x in f {
                x.makeThumb()
            }
            
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
    
    init(_ path:String, kinds:[String], isImage:Bool = true,post:Bool=false){
        source = path
        files = FileLoader.contentsOf(path, kinds:kinds, isImage:isImage)
        if (post){
            process()
        }
    }
    
    init(recursive path:String, kinds:[String], isImage:Bool = true,post:Bool=false){
        source = path
        files = FileLoader.recursive(dirs:[source], kinds:kinds, isImage:isImage)
        if (post){
            process()
        }
    }
    
    
    
    
}
