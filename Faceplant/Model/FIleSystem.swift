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

class FileLoader  : BindableObject, Codable {
    

    let files:[ACFileStatus]
    var source:String
    let didChange = PassthroughSubject<FileLoader, Never>()
    weak var loader:ProgressMonitor? = nil
    
    enum CodingKeys: String, CodingKey {
        case files
        case theshold
        case selectIndex
        case source
    }
    
    var groups: [ACFileGroup] = [] {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
        }
    }
    
    var theshold:Float = 10.0  {
        didSet {
            self.makeClusters()
        }
    }
    
    var selectIndex:Int = -1  {
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
            
        }
    }
    
    static func contentsOf(_ path:String, kinds:[String], isImage:Bool = true)->[String]{
        
        let f = FileManager.default
        let list = kinds.map({$0.uppercased()}).map{ $0.replacingOccurrences(of: ".", with: "")}
        
        let keep = Set<String>(list)
        var files: [String] = []
        do {
            for  x in try f.contentsOfDirectory(atPath: path){
                let filekid = (x as NSString).pathExtension.uppercased()
                if keep.contains(filekid){
                    //let info = ACFileStatus(path: (path as NSString).appendingPathComponent(x), isImage: isImage){
                    files.append((path as NSString).appendingPathComponent(x))
                }
            }
        } catch {
            print(error)
        }
        
        return files
    }
    
    static func recursive(dirs:[String], kinds:[String], isImage:Bool = true)->[ String]{
        
        let f = FileManager.default
        var files: [String] = []
        
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
    
    func makeClusters(){
        
        DispatchQueue.global(qos: .background).async { [weak loader] in
            
            guard !self.files.isEmpty else { return }
            let k1 = "cluster \(self.source)"
            loader?.add(key: k1, name: "clustering", total: self.files.count + 1)
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
                loader?.update(key: k1, amount: 1)
                
            }
            
            ret.append(ACFileGroup(current))
            print("we have \(ret.count) groups for \(self.theshold)")
            DispatchQueue.main.async {
                self.groups = ret
                 loader?.finish(key: k1)
            }
        }
    }
    
  
    
    private init(path:String, existing f:[ ACFileStatus],  otherLoader:FileLoader? = nil){
        source = path
        files = f.sorted{$0.info.key < $1.info.key}
        if let o = otherLoader {
            selectIndex = o.selectIndex
            theshold = o.theshold
        }
      
    }
    
    static let empty = FileLoader(path: "", existing: [])
    
    private convenience init(path:String,
                             paths:Set<String>,
                             isImage:Bool,
                             loader:ProgressMonitor?){
        let savePath = URL(fileURLWithPath: (path as NSString).appendingPathComponent("Status.json"))
        let decoder =  JSONDecoder()
        
        var statusArray:[ACFileStatus] = []
        var other:FileLoader? = nil
        let unknowns:[String]
        if let data = try? Data(contentsOf: savePath, options: .mappedIfSafe),
            let main  = try? decoder.decode(FileLoader.self,from: data) {
            //
            statusArray =  main.files.filter{paths.contains($0.info.path)}
            let excludePaths = Set<String>(statusArray.map({return $0.info.path}))
            unknowns = paths.filter({return !excludePaths.contains($0)})
            other = main
        } else {
            unknowns = Array(paths)
        }
        
        if !unknowns.isEmpty{
        
            let k1 = "checking \(path)"
            let k2 =  "\(path)analyze"
            let mName = (path as NSString).lastPathComponent
        loader?.add(key:k1, name: "check \(mName)", total: unknowns.count)
        loader?.add(key:k2, name: "look \(mName)", total: unknowns.count)
            
            var details:[ACFileStatus] = []
            for x in unknowns {
                if let a = ACFileStatus(path: x, isImage: isImage){
                    details.append(a)
                }
                loader?.update(key: k1, amount: 1)
            }
            
            loader?.finish(key: k1)
            for y in details{
                y.analyse()
                loader?.update(key: k2, amount: 1)
            }
            loader?.finish(key: k2)
            
            statusArray.append(contentsOf: details)
        }
        
        
        self.init(path:path, existing: statusArray,   otherLoader:other)
        
    }
    
    convenience init(flat path:String, kinds:[String], isImage:Bool = true,loader:ProgressMonitor?){
        
        let paths = Set<String>(FileLoader.contentsOf(path, kinds:kinds, isImage:isImage))
        print("got some files \(path.count)")
        
        self.init(path:path,paths:paths,isImage:isImage,loader:loader)
        
        
    }
    
    convenience init(recursive path:String, kinds:[String], isImage:Bool = true,loader:ProgressMonitor?){
        let paths = Set<String>(FileLoader.recursive(dirs:[path], kinds:kinds, isImage:isImage))
        self.init(path:path,paths:paths,isImage:isImage,loader:loader)
        
    }
    
    func save( _ savePath:String?=nil){
        let jsonEncoder = JSONEncoder()
        
        let url:URL
        
        if let p = savePath{
           url = URL(fileURLWithPath: p)
        } else {
            url = URL(fileURLWithPath: (source as NSString).appendingPathComponent("Status.json"))
        }
        jsonEncoder.outputFormatting = .prettyPrinted
        if let data =  try? jsonEncoder.encode(self){
            // print(s)
            try? data.write(to:url)
        }
    }
    
    func exclude(other:FileLoader)->FileLoader{
        let exclude = Set<String>(other.files.map({return $0.info.key}))
        let nextFiles = files.filter({!exclude.contains($0.info.key)})
        return FileLoader(path: self.source, existing: nextFiles)
        
    }
    
    func search(term:String)->FileLoader{
        
        let nextFiles = files.filter({$0.matches(term)})
        return FileLoader(path: self.source, existing: nextFiles)
        
    }
    
}
