//
//  main.swift
//  FaceProcessor
//
//  Created by Arthur Conner on 7/10/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation


extension ACFileStatus{
    
    func distance(_ other:ACFileStatus,unknown:Float)->Float{
        guard let f = self.features, let o = other.features else {
            return unknown
        }
        var distance = Float(0)
        if let _ = try? f.computeDistance(&distance, to: o){
            return  distance
        }
        return unknown
    }
    
}

let start = Date()
var last = Date()

func checkTime(_ label:String){
    let stop = -start.timeIntervalSinceNow
    let segment = -last.timeIntervalSinceNow
    print("\(label) \(stop) and \(segment)")
    last = Date()
}

extension  FileLoader  {
    
    func findFar(count:Int,tot:Int = 10){
        print("starting")
        let sample = files.prefix(tot).filter{ $0.features != nil }
        checkTime("computed distances")
        guard !sample.isEmpty else {
            print("Nothing to process")
            return}
        print("working with \(sample.count) items for \(count) clusters")
        
        var centroids:[ACFileStatus] = [sample[0]]
        var clusters:[[ACFileStatus]] = []
        var distance = Float(0)
        
        while centroids.count < count {
            
            let vals = sample.map({ x in
                
                return (totalDistance:centroids.reduce(Float(0)){ total, check in
                    return total + x.distance(check,unknown: 0)
                },value:x)
            })
            
            let winner = vals.reduce(vals[0]){ best, next in
                if next.totalDistance > best.totalDistance {
                    return next
                }
                return best
            }
            
            centroids.append(winner.value)
            print("got centroid \(winner.value.key)")
            
        }
        
        checkTime("got initial centroids")
        
        
        
        for _ in 0..<4{
            
            let foo = centroids.map({$0.key}).joined(separator: "; ")
            checkTime("centroids \(foo)")
            
            clusters.removeAll()
            for _ in 0..<centroids.count{
                clusters.append([])
            }
            
            for x in sample {
                var bestIndex:Int? = nil
                var bestValue:Float = 0
                
                for i in 0..<centroids.count{
                    let center = centroids[i]
                    
                    let dist = x.distance(center,unknown: 1000000)
                    
                    if let _ = bestIndex,
                        dist < bestValue  {
                        bestValue = dist
                        bestIndex = i
                    }
                    if  (bestIndex == nil) {
                        bestValue = dist
                        bestIndex = i
                    }
                }
                if let i = bestIndex {
                    clusters[i].append(x)
                }
            }
            
            let bar = clusters.map({"\($0.count)"}).joined(separator: "; ")
            checkTime("clustersize \(bar)")
            
            func clusterInside(acluster:[ACFileStatus])->ACFileStatus{
                let allDistance = acluster.map { x in
                    
                    return (totalDistance:acluster.reduce(Float(0)){ total, check in
                        return total + x.distance(check,unknown: 100000)
                    },value:x)
                }
                
                let winner = allDistance.reduce(allDistance[0]){ best, next in
                    if next.totalDistance < best.totalDistance {
                        return next
                    }
                    return best
                }
                return winner.value
            }
            
            centroids = clusters.map({clusterInside(acluster:$0)})
            
            
        }
        
        for x in centroids{
            print("open \(x.info.path)")
        }
        
    }
    
    
    func updateKeeper(file:String){
        var handle:FileHandle? = nil
        do {
            handle = try FileHandle(forWritingTo: URL(fileURLWithPath: file))
            if let f = handle, let line = "path,year,month,term,value\n".data(using: .utf8) {
                f.seekToEndOfFile()
                f.write(line)
                
            }
        } catch {
            print(error)
        }
        for status in files {
            
            if status.info.path.contains( "/Keeper/") {
                status.isKeeper = true
                for (x,v) in status.categories{
                    let m = status.info.date.month ?? 0
                    let y = status.info.date.year ?? 0
                    if let f = handle, let line = "\"\(status.info.path)\",\(y),\(m),\"\(x)\",\(v)\n".data(using: .utf8)  {
                        f.write(line)
                    }
                }
            }
        }
        
        
        do {
            if let f = handle{
                try f.close()
            }
        } catch {
            print(error)
        }
        save()
    }
}

struct PhotoRecord{
    let path:String
    let month:Int
    let year:Int
    let category:String
    let level:Float
    
    static func from(_ s:String)-> PhotoRecord? {
        
        let records = s.split(separator: ",")
        
        guard records.count == 5 else {
            return nil
        }
        
        let path:String = records[0].replacingOccurrences(of: "\"", with: "")
        let month:Int = Int(records[2]) ?? 0
        let year:Int = Int(records[1]) ?? 0
        let category:String = records[3].replacingOccurrences(of: "\"", with: "")
        let level:Float  = Float(records[4]) ?? 0
        return PhotoRecord(path: path, month: month, year: year, category: category, level: level)
    }
    
    static func run(file:String =  "/Users/arthurconner/code/photostudy/terms.csv"){
        guard let file = try? String(contentsOfFile:file) else {
            print("no go")
            fatalError()
        }
        
        let records = file.split(separator: "\n").compactMap{rec in
            return PhotoRecord.from(String(rec))
        }
        
        for i in 1..<5{
            print(records[i])
        }
        
        let commonset:Set<String> = ["people","child","teen","structure","adult"]
        
        for y in 2016..<2019{
            for m in 1..<13{
                let vals = records.filter({$0.year == y && $0.month == m})
                if !vals.isEmpty {
                    
                    let freq:[String:Float] = vals.reduce(into: [String: Float](),{ dict,  rec in
                        if (!commonset.contains(rec.category)){
                            dict[rec.category] = dict[rec.category,default:0] + rec.level
                        }
                    })
                    
                    if let f = freq.first{
                        let winner = freq.reduce(f,{best,current in
                            if current.value > best.value  {
                                return current
                            }
                            return best
                        })
                        print("\(m) \(y) \(winner.key) in \(winner.value)")
                        let winList = vals.filter({$0.category == winner.key})
                        for x in winList {
                            print("open \(x.path)")
                        }
                    }
                } else {
                    print("\(m) \(y) no records")
                }
                
            }
        }
    }
}





//let winner:[String,
let file = "/Users/arthurconner/code/photostudy/vals.csv"

do {
    if  FileManager.default.fileExists(atPath: file) {
        try FileManager.default.removeItem(atPath: file)
    }
      FileManager.default.createFile(atPath: file, contents: nil, attributes: nil)
} catch {
    print("error with files \(error)")
}

let loud = LoudProgress()
let main = FileLoader(recursive: "/Volumes/Zoetrope/images", kinds: ["JPG","JPEG","PNG"], isImage: true,loader: loud)
main.updateKeeper(file: file)
PhotoRecord.run(file: file)





