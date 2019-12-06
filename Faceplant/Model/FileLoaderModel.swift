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
    
    let path:String
    let label:String
     
    var monitor = LoudProgress()
    
    var isComputingCluster = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    func computeClusters(){
        guard let m = self.model else {return}
        
        FileLoaderModelQue.async {
            [weak self] in
            let c =  m.makeClusters(loader: self?.monitor)
            DispatchQueue.main.async {
                [weak self ] in
                if let m = self?.model{
                    m.matchPhotos = c
                    self?.model = m
                }
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
                self?.computeClusters()
            }
        }
        
        
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
