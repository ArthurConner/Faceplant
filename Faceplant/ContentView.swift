//
//  ContentView.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/8/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import SwiftUI


struct FileView : View {
    
   @ObjectBinding var info:ACFileStatus
   
    var body: some View {
        info.loadImage()
        
       
        return VStack{
            if (info.image != nil){
            Image(info.image!, scale: 60, label: Text("ouch"))
            } else {
                 Text("Loading").frame( height: 160)
            }
         
            
        }
    }
    
}

struct ContentView : View {
    
    static let foo =  FileLoader("/Volumes/Zoetrope/images/2018/09/Keeper", kinds: [".JPG"], isImage: true)
    
    var body: some View {
       
        Group{
        List(ContentView.foo.allFiles) { landmark in
            FileView(info: landmark)
            
        }
        
        Text("Hello World")
           
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
