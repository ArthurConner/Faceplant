//
//  FileLoaderModel.swift
//  Faceplant
//
//  Created by Arthur Conner on 12/6/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

fileprivate let FileLoaderModelQue = DispatchQueue(label: "FileLoaderModelQue", qos: .userInitiated, attributes:  [], autoreleaseFrequency: .workItem, target: nil)

class FileLoaderModel  :   ObservableObject {
    
    @Published var model:FileLoader?
    @Published var error: String? = nil
    @Published var groups:[ACFileGroup] = []
    @Published var threshold:Double = 0
    @Published var selected:Set<FileInfo> = []
   // @Published var matchPhotos: [ACFileGroup] = []
    
    let path:String
    let label:String
    
    var monitor = LoudProgress()
    
    // @Published var isComputingCluster = 10.0
    
    private var subscriptions = Set<AnyCancellable>()
    
    func computeClusters(_ x:Double){
       
        guard let m = self.model else {return}
        guard x > 0 else {
            print("not going to compute clusters")
            
            return}
        
         print("About to compute \(x)")
        // isComputingCluster = -m.theshold - 1
        m.theshold = Float(x)
        
        FileLoaderModelQue.async {
            [weak self] in
            let c =  m.makeClusters(loader: self?.monitor)
            DispatchQueue.main.async {
                [weak self ] in
                if let m = self?.model{
                    self?.groups = c
                    m.matchPhotos = c
                    m.save()
                }
                self?.groups = c
            }
        }
    }
    
    init(path:String,label:String) {
        
        self.path = path
        self.label = label
        
        FileLoaderModelQue.async {
            [weak self ] in
            let m = FileLoader(recursive:path, kinds: [".JPG"], isImage: true,loader: self?.monitor,name:"\(label).json")
            DispatchQueue.main.async {
                [weak self ] in
                self?.model = m
                self?.groups = m.matchPhotos ?? []
                self?.threshold = Double(m.theshold)
                self?.computeClusters(Double(m.theshold))
            }
        }
        
        $threshold.receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .sink(receiveCompletion: {[weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = "\(error)"
                }
                }, receiveValue: { x in
                    if x >= 0 {
                        self.computeClusters(x)
                    }
                    self.error = nil
            })
            .store(in: &subscriptions)
        
        
        $model.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.error = "\(error)"
                }
            }, receiveValue: { x in
                if let model = x {
                    model.save()
                   
                }
                self.error = nil
            })
            .store(in: &subscriptions)
    }
}
