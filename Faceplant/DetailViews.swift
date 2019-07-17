//
//  ContentView.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/8/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import SwiftUI



struct ThumbnailView : View {
    
    @ObjectBinding var info:ACFileStatus
    
    
    var body: some View {
        let im:NSImage
        if let i = info.image{
        im = i
        } else {
            im = NSImage(named: "empty.jpeg")!
            info.loadImage()
        }
        
        let rad:CGFloat = 8
        
      
        
        if info.isKeeper{
            return Image(nsImage: im)
                .resizable()
                .frame(width: im.size.width , height: im.size.height ).padding()
                .background(Color.blue.cornerRadius(rad))
        } else {
            return Image(nsImage: im)
                .resizable()
                .frame(width: im.size.width , height: im.size.height ).padding(6)
                .background(Color.gray.cornerRadius(rad))
        }
    }
    
}

struct DetailView : View {
    
    @ObjectBinding var loader:FileLoader
    @ObjectBinding var info:ACFileStatus
    
    func imageDetail()->AnyView{
        let im = info.makeScale(maxDim: 600)!
        let rad:CGFloat = 8
        
        if info.isKeeper{
            return AnyView(
                Image(nsImage: im)
                    .frame(width: im.size.width , height: im.size.height ).padding(3)
                    .background(Color.blue.cornerRadius(rad))
            )
            
        } else {
            return AnyView(Image(nsImage: im)
                .frame(width: im.size.width , height: im.size.height ).padding(3)
                .background(Color.gray.cornerRadius(rad))
            )
            
        }
    }
    
    var body: some View {
        HStack{
            imageDetail()
            VStack{
                Toggle(isOn: $info.isKeeper){
                    Text("Keep")
                }
                //Toggle(loader.files[max(loader.selectIndex,0)]).keeper,
            }
        }
    }
    
}





