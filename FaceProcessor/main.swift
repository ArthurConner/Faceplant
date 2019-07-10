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

    
    
}

print("Hello, World!")



let main = FileLoader(recursive: "/Volumes/Zoetrope/images", kinds: ["JPG"], isImage: true)
checkTime("Loaded files")
main.findFar(count: 8, tot: 9000)




