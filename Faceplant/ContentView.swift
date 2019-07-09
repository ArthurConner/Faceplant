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
        
        Image(nsImage: info.image!)
            .frame(width: ACFileStatus.thumbSize.width * 2, height: ACFileStatus.thumbSize.height * 2).background(Color.orange)
        
        
        
    }
    
}

struct GroupView : View {
    
    var group:ACFileGroup
    
    var body: some View {
        
        //let im = group.members.filter({$0.image != nil}).first?.image
        
        return ScrollView(.horizontal, showsIndicators: true){
            
            HStack{
                
                ForEach(group.members.filter({$0.image != nil})){ x in
                    Image(nsImage: x.image!).frame(width: ACFileStatus.thumbSize.width , height: ACFileStatus.thumbSize.height ).padding()
                        .background(Color.white.cornerRadius(8))
                }
            }.padding()
            
            
            
        }
        
        
        /*
         
         return ScrollView(.horizontal, showsIndicators: true){
         HStack{
         List(group.members.filter({$0.image != nil})) { landmark in
         FileView(info: landmark)
         
         }
         }.frame(height: ACFileStatus.thumbSize.height)
         }.background(Color.yellow)
         */
        
    }
    
}

struct ContentView : View {
    
    @ObjectBinding var myGroups =  FileLoader("/Volumes/Zoetrope/Keeper", kinds: [".JPG"], isImage: true, post:true)
    
    var body: some View {
        
        Group{
            if (!myGroups.groups.isEmpty){
                Slider(value: $myGroups.theshold, from: 1, through: 40, by: 0.5)
            }
            
            ScrollView(.vertical, showsIndicators: true){
                // VStack{
                ForEach(myGroups.groups) { landmark in
                    GroupView(group: landmark)
                    
                }.padding()
                //}.background(Color.purple)
            }.padding()
            //  .background(Color.pink)
            
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
