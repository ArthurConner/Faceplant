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
        let rad:CGFloat = 8
        
        if info.isKeeper{
            return Image(nsImage: im)
                .frame(width: im.size.width , height: im.size.height ).padding()
                .background(Color.blue.cornerRadius(rad))
        } else {
            return Image(nsImage: im)
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
        
    }
    
}

struct ContentView : View {
    
    @ObjectBinding var obj:ProgessWatcher<FileLoader>
 
    
    var body: some View {
        let myGroups = obj.item
        let details = obj.monitor.details
       
        return Group{
            
            if !details.isEmpty{
                ProgressGroupView(monitor: obj.monitor).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
            if (!myGroups.groups.isEmpty){
                Slider(value: $obj.item.theshold, from: 1, through: 40, by: 0.5)
                DetailView(loader: myGroups,info: myGroups.files[max(0,myGroups.selectIndex)])
            }
            
            ScrollView(.vertical, showsIndicators: true){
                // VStack{
                ForEach(myGroups.groups) { landmark in
                    GroupView(group: landmark)
                    
                }
                //}.background(Color.purple)
            }.padding().padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            //  .background(Color.pink)
            
        }
        
    }
    
}
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        let mymont = ProgessWatcher(item: FileLoader(flat:"/Volumes/Zoetrope/Keeper", kinds: [".JPG"], isImage: true,loader: nil))
        return ContentView(obj:mymont)
    }
}
#endif
