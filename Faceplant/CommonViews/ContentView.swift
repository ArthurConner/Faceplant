import SwiftUI


extension ACFileStatus {
    func background(rad:CGFloat)-> some View{
        if isKeeper {
            return Color.blue.cornerRadius(rad)
        } else {
            return Color.gray.cornerRadius(rad)
        }
    }
}


struct DetailView : View {
    
    @ObjectBinding var loader:FileLoader
    @ObjectBinding var info:ACFileStatus
    @ObjectBinding var im:ImageFileResource
    
    let radius:CGFloat
    
    var body: some View {
        im.reload()
        
        return HStack{
            ThumbnailView(info: info, im: im, radius: radius)
            VStack{
                Toggle(isOn: $info.isKeeper){
                    Text("Keep")
                }
            }
        }
    }
}

struct GroupView : View {
    
    var group:ACFileGroup
    @ObjectBinding var loader:FileLoader
    
    var body: some View {
     
        return ScrollView(.horizontal, showsIndicators: true){
            
            HStack{
                //.filter({$0.image != nil})
                ForEach(group.members){ x in
                    ThumbnailView(info: x,im: x.image,radius:3)
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
 
                    DetailView(loader: myGroups,
                               info: myGroups.files[max(0,myGroups.selectIndex)],
                               im: ImageFileResource(
                                url: myGroups.files[max(0,myGroups.selectIndex)].info.path, maxDim: ImageFileResource.largeSize),
                               radius:10)
                    List(myGroups.groups) { landmark in
                        GroupView(group: landmark, loader: myGroups).frame(height:ImageFileResource.thumbSize.height + 10)
                        
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
