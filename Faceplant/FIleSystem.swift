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


struct FileInfo {
    let path: String
    let date: DateComponents

   
    
    let id: UUID = UUID()
    
    var key:String{
        let y = date.year ?? 2000
        let m = date.month ?? 0
        return NSString.path(withComponents: ["\(y),\(m)"])
    }
    
   
    
    static func make(path:String,isImage:Bool)->(String,FileInfo)?{
        let f = FileManager.default
        var ret:FileInfo?
        
        do {
            let attrs = try f.attributesOfItem(atPath: path)
            
            if let creationDate = attrs[.creationDate] as? Date{
                let calendar = Calendar.current
                ret = FileInfo(path: path,date: calendar.dateComponents([.year, .month], from: creationDate))
            }
     
        } catch {
            
        }
        
        if false,
            isImage,
            let url = NSURL(string: path),
            let imageSource = CGImageSourceCreateWithURL(url, nil),
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?{
 
            let exifDict = imageProperties[kCGImagePropertyExifDictionary]
            print(exifDict as Any)
         
            
        }
        
        
        if let r = ret {
            let fname = (path as NSString).lastPathComponent
            
            return ("\(r.key)-->\(fname)",r)
        }
        return nil
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
    
    var image:CGImage?{
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
        let r = NSString.path(withComponents: [root,info.key,last,(info.path as NSString).lastPathComponent ])
        return r
        
    }
    
    
    func loadImage(){
        guard (self.image == nil ) else { return }
        ACFileStatus.queue.async {
            var sampRect = NSRect(x: 0, y: 0, width: 400, height: 400)
            
            if let im = NSImage(contentsOfFile: self.info.path)?.cgImage(forProposedRect: &sampRect, context: NSGraphicsContext.current, hints: nil){
                self.image = im
                
                
            }
        }
    }
    
    
}
extension ACFileStatus : Identifiable{
    public var id:UUID {
        return info.id
    }
}

extension ACFileStatus : BindableObject {
    
}


class FileLoader {
    
    var files: [String: ACFileStatus] = [:]
    var source:String
    
    
    static func contentsOf(_ path:String, kinds:[String], isImage:Bool = true)->[String: ACFileStatus]{
        
        let f = FileManager.default
        let list = kinds.map({$0.uppercased()}).map{ $0.replacingOccurrences(of: ".", with: "")}
        
      let keep = Set<String>(list)
        var files: [String: ACFileStatus] = [:]
        do {
            for  x in try f.contentsOfDirectory(atPath: path){
                if keep.contains((x as NSString).pathExtension),
                    let info = ACFileStatus(path: (path as NSString).appendingPathComponent(x), isImage: isImage){
                    files[info.key] = info
                }
            }
        } catch {
            print(error)
        }
        
        return files
    }
    
    static func recursive(dirs:[String], kinds:[String], isImage:Bool = true)->[String: ACFileStatus]{
        
        let f = FileManager.default
        var files: [String: ACFileStatus] = [:]
        
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
                        for (k,v) in adds {
                            files[k] = v
                        }
                    }
                    
                }
            } catch {
                print(error)
            }
            
            let adds = FileLoader.contentsOf(dir, kinds: kinds, isImage: isImage)
            
            for (k,v) in adds {
                files[k] = v
            }
            
        }
        
        return files
        
    }
    
    init(_ path:String, kinds:[String], isImage:Bool = true){
        source = path
        files = FileLoader.contentsOf(path, kinds:kinds, isImage:isImage)
    }
    
    init(recursive path:String, kinds:[String], isImage:Bool = true){
        source = path
        files = FileLoader.recursive(dirs:[source], kinds:kinds, isImage:isImage)
    }
    
   var allFiles:[ACFileStatus]{
        return files.values.sorted(by: {$0.info.path < $1.info.path})
    }
    
    
}
