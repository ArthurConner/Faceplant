//
//  ImageResource.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/17/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

#if os(OSX)
typealias OSImage = NSImage
#else
typealias OSImage = UIImage
#endif

fileprivate  let imagequeue = DispatchQueue(label: "thumbnailqueue", qos: .userInitiated, attributes:  [], autoreleaseFrequency: .workItem, target: nil)

class ImageFileResource: BindableObject {
    var didChange: AnyPublisher<OSImage?, Never> = Publishers.Empty().eraseToAnyPublisher()
    private let subject = PassthroughSubject<OSImage?, Never>()
    let url:String
    let maxDim:CGFloat
    
    private var firstLoad = true
    
    var image = OSImage(named: "empty.jpeg")! {
        didSet {
            DispatchQueue.main.async {
                self.subject.send(self.image)
            }
        }
    }
    
    init(url: String,maxDim: CGFloat) {
        self.url = url
        self.maxDim = maxDim
        self.didChange = subject.handleEvents(receiveSubscription: { [weak self] sub in
            guard let s = self, s.firstLoad else { return }
            
            s.reload()
            
        }).eraseToAnyPublisher()
    }
    
    func reload() {
        guard firstLoad == true else { return}
        firstLoad = false
        imagequeue.async{
            [weak self] in
            if let im = self?.makeScale(){
                self?.image = im
            }
            
        }
        
    }
    
    #if os(OSX)
    
    static let thumbSize = NSSize(width: 128, height: 128)
    static let largeSize:CGFloat = 600
    func makeScale()->NSImage?{
        
        let url = URL(fileURLWithPath: self.url)
        
        print("making thumbnail: \(self.url)")
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
    static let largeSize:CGFloat = 300
    
    func makeScale()->OSImage?{
        print("making thumbnail: \(self.url) size \(maxDim)")
        if let im = UIImage(contentsOfFile: self.url){
            let longest = max(im.size.height,im.size.width)
            let scale = maxDim/longest
            let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            return   renderer.image { (context) in
                im.draw(in: CGRect(origin: .zero, size: size))
            }
            
        }
        return nil
    }
    
    #endif
    
}


