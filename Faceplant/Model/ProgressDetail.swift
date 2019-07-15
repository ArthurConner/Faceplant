//
//  ProgressDetail.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/15/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class ProgressMonitor : BindableObject {
    
    private class Progress{
        var name:String
        var distance:Int
        var total:Int
        var updates = Date()
        
        init(name n:String, total t:Int) {
            self.distance = 0
            self.name = n
            self.total = t
        }
        
        func update(amount:Int){
            updates =  Date()
            self.distance = min(self.distance+amount,total)
        }
        var isDone:Bool{
            return self.distance >= self.total
        }
        
        var record:(name:String,last:Date,distance:Int,total:Int){
            return (name:self.name,last:updates,distance:distance,total:total)
        }
        
    }
    private var keeper:[String:Progress] = [:]{
        didSet {
            updateMe()
        }
    }
    
    let didChange = PassthroughSubject<ProgressMonitor, Never>()
    
    init(){
        
    }
    
    private func updateMe(){
        DispatchQueue.main.async {
            self.didChange.send(self)
        }
    }
    
    func add(key:String,name:String, total:Int){
        keeper[key] = Progress(name: name, total: total)
        updateMe()
    }
    
    func update(key:String,amount:Int) {
        guard let x = keeper[key] else {
            print("trying to update progress on \(key) and we don't know about it")
            return
        }
        
        
        if amount + x.distance >= x.total {
            finish(key: key)
        } else {
            x.update(amount: amount)
            //print("updating \(key) \(x.distance) out of \(x.total)")
            updateMe()
        }
    }
    
    func finish(key:String){
        keeper.removeValue(forKey: key)
        updateMe()
        
    }
    
    var details:[(name:String,last:Date,distance:Int,total:Int)]{
        return self.keeper.values.map{ $0.record }.sorted(by: {$0.name < $1.name})
    }
    
    fileprivate func info(of:String)->(name:String,last:Date,distance:Int,total:Int)?{
        
        return self.keeper[of]?.record
    }
    
}

class LoudProgress : ProgressMonitor {
    private  var lastTime:[String:Date] = [:]
    var interval:TimeInterval = 3
    
    override func add(key: String, name: String, total: Int) {
        lastTime[key] = Date()
        super.add(key: key, name: name, total: total)
    }
    override func update(key: String, amount: Int) {
       super.update(key: key, amount: amount)
        if let d = lastTime[key],
            d.timeIntervalSinceNow < -interval,
            let x  = super.info(of: key){
            print("updating \(key) \(x.distance) out of \(x.total)")
            lastTime[key] = Date()
        }
    }
    
    override func finish(key: String) {
        super.finish(key: key)
        lastTime.removeValue(forKey: key)
    }
}

class ProgessWatcher<A:BindableObject>: BindableObject {
    var item:A
    var monitor = ProgressMonitor(){
        didSet {
            updateMe()
        }
    }
    
    private func updateMe(){
        DispatchQueue.main.async {
            self.didChange.send((item:self.item,monitor:self.monitor))
        }
    }
    var didChange = PassthroughSubject<(A,ProgressMonitor),Never>()
    
    init(item i:A){
        self.item = i
        
        let _ = self.monitor.didChange.sink(receiveValue: {[weak self] (x) in
            if let s = self {
                s.updateMe()
            }
        })
      
        let _ = self.item.didChange.sink(receiveValue: {[weak self] (x) in
            if let s = self {
               s.updateMe()
            }
        })
        
    }
    
}
