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
    
    private init(path:String, _ f:[ ACFileStatus], _ other:FileLoader? = nil){
        source = path
        files = f.sorted{$0.info.key < $1.info.key}
        if let o = other {
            selectIndex = o.selectIndex
            theshold = o.theshold
        }
    }
    
    private convenience init(path:String, paths:Set<String>,isImage:Bool){
        let savePath = URL(fileURLWithPath: (path as NSString).appendingPathComponent("Status.json"))
        let decoder =  JSONDecoder()
       
        var statusArray:[ACFileStatus] = []
        var other:FileLoader? = nil
        let unknowns:[ACFileStatus]
        if let data = try? Data(contentsOf: savePath, options: .mappedIfSafe),
            let main  = try? decoder.decode(FileLoader.self,from: data) {
            //
            statusArray =  main.files.filter{paths.contains($0.info.path)}
            let excludePaths = Set<String>(statusArray.map({return $0.info.path}))
            unknowns = paths.filter({return !excludePaths.contains($0)}).compactMap({return ACFileStatus(path: $0, isImage: isImage)})
            other = main
        } else {
            unknowns = paths.compactMap({return ACFileStatus(path: $0, isImage: isImage)})
        }
        
        statusArray.append(contentsOf: unknowns)
        for x in unknowns {
            x.analyse()
        }
        
        self.init(path:path,statusArray, other)
        
    }
    
    convenience init(_ path:String, kinds:[String], isImage:Bool = true){

        let paths = Set<String>(FileLoader.contentsOf(path, kinds:kinds, isImage:isImage))
        
        self.init(path:path,paths:paths,isImage:isImage)
        
        
    }
    
    convenience init(recursive path:String, kinds:[String], isImage:Bool = true){
        let paths = Set<String>(FileLoader.recursive(dirs:[path], kinds:kinds, isImage:isImage))
        self.init(path:path,paths:paths,isImage:isImage)
    
    }
    
    func save(){
        let jsonEncoder = JSONEncoder()
        
        jsonEncoder.outputFormatting = .prettyPrinted
        if let data =  try? jsonEncoder.encode(self){
           // print(s)
            try? data.write(to:URL(fileURLWithPath: (source as NSString).appendingPathComponent("Status.json")))
        }
    }
    
    func exclude(other:FileLoader)->FileLoader{
        let exclude = Set<String>(other.files.map({return $0.info.key}))
        let nextFiles = files.filter({!exclude.contains($0.info.key)})
        return FileLoader(path: self.source, nextFiles)
        
    }
    
    func search(term:String)->FileLoader{
       
        let nextFiles = files.filter({$0.matches(term)})
        return FileLoader(path: self.source, nextFiles)
        
    }

}
