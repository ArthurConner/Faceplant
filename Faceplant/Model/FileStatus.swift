//
//  FileStatus.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/10/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation
import SwiftUI
import ImageIO
import Combine
import Vision


struct FileInfo : Codable {
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


struct PeopleBounds : Codable{
    let name:String
    let bounds:CGRect
}

class ACFileStatus : Codable{
    let info: FileInfo
    
    var key:String{
        willSet {
            updateMe()
        }
    }
    var categories: [String: Float] = [:]
    var terms: [String: Float] = [:]
    var people:[PeopleBounds] = []
 
    enum CodingKeys: String, CodingKey {
        case info = "file"
        case key = "StatusKey"
        case isKeeper = "Keeper"
        case categories
        case terms
        case people
        // case searchterms = "Terms"
        //case faces
    }
    
    let willChange = PassthroughSubject<ACFileStatus, Never>()
    
    init?(path:String,isImage:Bool){
        guard let (s,i) = FileInfo.make(path: path, isImage: isImage) else { return nil}
        self.key = s
        self.info = i
        // print("making item")
    }
    
    func updateMe(){
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.willChange.send(self)
        }
    }
    
    var isKeeper = false{
        willSet {
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
        return ImageFileResource(url: info.path, maxDim: ImageFileResource.thumbSize.width)
    }()
    
    lazy var features:VNFeaturePrintObservation? = {
        //print("features: \(self.info.path)")
        let url = URL(fileURLWithPath: info.path)
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            try requestHandler.perform([request])
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
    
    
    func matches(_ m:String)->Bool{
        for (k, _) in terms {
            if  m.caseInsensitiveCompare(k) == .orderedSame {
                return true
            }
        }
        for (k, _) in categories {
            if  m.caseInsensitiveCompare(k) == .orderedSame {
                return true
            }
        }
        return false
    }
    
    func analyse(){
        
        let url = URL(fileURLWithPath: info.path)
        
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNClassifyImageRequest()
        
        try? handler.perform([request])
        
        // Process classification results
        if let observations = request.results  as? [VNClassificationObservation] {
            
            categories = observations
                .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
                .reduce(into: [String: VNConfidence]()) { dict, observation in dict[observation.identifier] = observation.confidence }
            
            terms = observations
                .filter { $0.hasMinimumPrecision(0.01, forRecall: 0.7) }
                .reduce(into: [String: VNConfidence]()) { (dict, observation) in dict[observation.identifier] = observation.confidence }
        }  else    {
            categories = [:]
            terms = [:]
            
        }
        //print("got cats")
        
        let req2 = VNDetectHumanRectanglesRequest()
        
        try? handler.perform([req2])
        
        // Process classification results
        if let observations = req2.results  as? [VNDetectedObjectObservation] {
            people = observations.map{PeopleBounds(name: "unknown", bounds: $0.boundingBox)}
            
            
        } else {
            //print(" foo \(req2.results)")
            people = []
        }
        //print("got pep")
        
    }
    
}

extension ACFileStatus : ObservableObject {
    
}
