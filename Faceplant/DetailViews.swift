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


struct GroupView : View {
    
    var group:ACFileGroup
    @ObjectBinding var loader:FileLoader
    
    /*
  
    func imageDetail(info:ACFileStatus)->AnyView{
        
        guard let im = info.image else {
            return AnyView(
                Text("Loading")
                info.imagereload()
            )
        }
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
    */
    
    var body: some View {
        
        //let im = group.members.filter({$0.image != nil}).first?.image
        
        return ScrollView(.horizontal, showsIndicators: true){
            
            HStack{
                //.filter({$0.image != nil})
                ForEach(group.members){ x in
                    ThumbnailView(info: x)
                        .tapAction {
                            if let i = self.loader.indexOf(key:x.key){
                                self.loader.selectIndex = i
                                self.loader.save()
                            }
                    }
                    
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
                ProgressGroupView(monitor: obj.monitor)
            } else {
                if (!myGroups.groups.isEmpty){
                    Slider(value:$obj.item.theshold, from: 1, through: 40, by: 0.5)
                    DetailView(loader: myGroups,info: myGroups.files[max(0,myGroups.selectIndex)])
                    
                    List(myGroups.groups) { landmark in
                        GroupView(group: landmark, loader: myGroups).frame(height:ACFileStatus.thumbSize.height + 10)
                        
                    }
                        
                        .background(Color.red)
                    
                } else {
                    List(myGroups.files) { landmark in
                        Text(landmark.key)
                        
                    }
                    .background(Color.orange)
                }
                
            }
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        let foo = ProgessWatcher(item: FileLoader.empty)
        return ContentView(obj: foo)
    }
}
#endif


