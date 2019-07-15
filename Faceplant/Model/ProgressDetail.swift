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
        var updates = [Date()]
        
        init(name n:String, total t:Int) {
            self.distance = 0
            self.name = n
            self.total = t
        }
        
        func update(amount:Int){
            updates.append( Date())
            self.distance = min(self.distance+amount,total)
        }
        var isDone:Bool{
            return self.distance >= self.total
        }
        
        var record:(name:String,last:Date,distance:Int,total:Int){
            return (name:self.name,last:updates.last ?? Date(),distance:distance,total:total)
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
        
        x.update(amount: amount)
        updateMe()
    }
    
    func finish(key:String){
        guard let x = keeper[key] else {
            print("trying to finish progress on \(key) and we don't know about it")
            return
        }
        update(key: key, amount: x.total)
    }
    
    var details:[(name:String,last:Date,distance:Int,total:Int)]{
        return self.keeper.values.map{ $0.record }.sorted(by: {$0.name < $1.name})
    }
    
}
