//
//  ContentView.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/8/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import SwiftUI

 #if os(OSX)

struct FileView : View {
    
    @ObjectBinding var info:ACFileStatus
    
    var body: some View {
        let im = info.image!
        
        return Image(nsImage: info.image!)
            .frame(width: inf , height: ACFileStatus.thumbSize.height ).padding()
            .background(Color.white.cornerRadius(8))
        
        
        
    }
    
}
#else

struct FileView : View {
    
    @ObjectBinding var info:ACFileStatus
    
    var body: some View {
         let im = info.image!
        let rad:CGFloat = 8
        
       
        if info.isKeeper{
            return Image(uiImage: im)
                .frame(width: im.size.width , height: im.size.height ).padding()
            .background(Color.blue.cornerRadius(rad))
        } else {
            return Image(uiImage: im)
                .frame(width: im.size.width , height: im.size.height ).padding(6)
            .background(Color.gray.cornerRadius(rad))
        }
        
        
        
    }
    
}

struct DetailView : View {
    
    @ObjectBinding var loader:FileLoader
    @ObjectBinding var info:ACFileStatus
   
    func imageDetail()->AnyView{
        //let index = max(loader.selectIndex,0)
       // let info = loader.files[index]
        
        let im = info.makeScale(maxDim: 300)!
        
        let rad:CGFloat = 8
        
        
        if info.isKeeper{
            return AnyView(
                Image(uiImage: im)
                .frame(width: im.size.width , height: im.size.height ).padding(3)
                .background(Color.blue.cornerRadius(rad))
            )
            
        } else {
            return AnyView(Image(uiImage: im)
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

#endif

struct GroupView : View {
    
    var group:ACFileGroup
    
    var body: some View {
        
        //let im = group.members.filter({$0.image != nil}).first?.image
        
        return ScrollView(.horizontal, showsIndicators: true){
            
            HStack{
                
                ForEach(group.members.filter({$0.image != nil})){ x in
                    FileView(info: x)
                }
            }
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
    
    @ObjectBinding var myGroups:FileLoader
    
    var body: some View {
        
        Group{
            if (!myGroups.groups.isEmpty){
                Slider(value: $myGroups.theshold, from: 1, through: 40, by: 0.5)
                DetailView(loader: myGroups,info: myGroups.files[max(0,myGroups.selectIndex)])
            }
            
            ScrollView(.vertical, showsIndicators: true){
                // VStack{
                ForEach(myGroups.groups) { landmark in
                    GroupView(group: landmark)
                    
                }
                //}.background(Color.purple)
            }.padding()
            //  .background(Color.pink)
            
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(myGroups:FileLoader("/Volumes/Zoetrope/Keeper", kinds: [".JPG"], isImage: true))
    }
}
#endif
