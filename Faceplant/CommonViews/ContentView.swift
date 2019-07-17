import SwiftUI

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
                    HStack{
                        if myGroups.isComputingCluster {
                            Circle().frame(width: 10, height: 10, alignment: .center).foregroundColor(.red)
                        } else {
                            Circle().frame(width: 10, height: 10, alignment: .center).foregroundColor(.green)
                        }
                        Slider(value:$obj.item.theshold, from: 1, through: 40, by: 0.5)
                    }
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
