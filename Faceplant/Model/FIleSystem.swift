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
    

    
    public private(set) var files:[ACFileStatus]{
        didSet {
            DispatchQueue.main.async {
                self.didChange.send(self)
            }
        }
    }
    
    private var outStanding:[String] = []
    
    var clusterOnLoad:Bool = false
    
    var source:String
    let didChange = PassthroughSubject<FileLoader, Never>()
    
    
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
    
    private func loadSome(i:Int,isImage:Bool){
        let max = self.outStanding.count
        let bump = 30
        
        guard (i < max) else {
            print("nothing outstanding")
            self.outStanding = []
           
            
            if clusterOnLoad {
            
            self.makeClusters()
            }
            return
        }
        print("\(self.outStanding.count - i) remain")
        
        
        let batch = Array(self.outStanding[i..<min(i+bump,max-1)])
       
     
            
        DispatchQueue.global(qos: .userInitiated).async {
           // [weak self] in
       
        let nextArray = batch.compactMap({ACFileStatus(path: $0, isImage: isImage)})
                
                for x in nextArray {
                    x.analyse()
                }
            
            DispatchQueue.main.async {
            // [weak self] in
                self.files.append(contentsOf: nextArray)
                self.save()
                let j = min(i+bump,max-1)
                
                    if j != i {
                        self.loadSome(i:j, isImage: isImage)
                    } else {
                        self.loadSome(i:max, isImage: isImage)
                }
                
            }
            
        }
        
       
    }
    
    private init(path:String, existing f:[ ACFileStatus],  otherLoader:FileLoader? = nil, outstanding out:[String]? = nil, isImage:Bool = true){
        source = path
        files = f.sorted{$0.info.key < $1.info.key}
        if let o = otherLoader {
            selectIndex = o.selectIndex
            theshold = o.theshold
        }
        if let p = out, !p.isEmpty{
            self.outStanding = p
            
            loadSome(i:0, isImage:isImage)
        }
    }
    
    private convenience init(path:String, paths:Set<String>,isImage:Bool){
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
        

        
        
        self.init(path:path, existing: statusArray,  otherLoader:other, outstanding:unknowns)
        
    }
    
    convenience init(_ path:String, kinds:[String], isImage:Bool = true){
        
        let paths = Set<String>(FileLoader.contentsOf(path, kinds:kinds, isImage:isImage))
        print("got some files \(path.count)")
        
        self.init(path:path,paths:paths,isImage:isImage)
        
        
    }
    
    convenience init(recursive path:String, kinds:[String], isImage:Bool = true){
        let paths = Set<String>(FileLoader.recursive(dirs:[path], kinds:kinds, isImage:isImage))
        self.init(path:path,paths:paths,isImage:isImage)
        
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
