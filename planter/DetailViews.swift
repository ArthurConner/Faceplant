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
    @ObjectBinding var im:ImageFileResource
    let radius:CGFloat
    
    var body: some View {
     
        Image(uiImage: im.image)
                .frame(width: im.image.size.width , height: im.image.size.height ).padding()
                .background(info.background(rad: radius))
        
    }
    
}

/*

struct DetailView : View {
    
    @ObjectBinding var loader:FileLoader
    @ObjectBinding var info:ACFileStatus
    @ObjectBinding var im:ImageFileResource
    

    var body: some View {
        
        let background:_ModifiedContent<Color, _ClipEffect<RoundedRectangle>>
           im.reload()
        if info.isKeeper {
            background  = Color.blue.cornerRadius(10)
        } else {
            background  = Color.gray.cornerRadius(10)
        }
        
        return HStack{
            Image(uiImage: im.image)
                .frame(width: im.maxDim , height: im.maxDim ).padding(3)
                .background(background)
            
            VStack{
                Toggle(isOn: $info.isKeeper){
                    Text("Keep")
                }
            }
        }
    }
    
}
*/


