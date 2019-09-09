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
    
    @ObservedObject var loader:FileLoader
    @ObservedObject var info:ACFileStatus
    @ObservedObject var im:ImageFileResource
    
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
    @ObservedObject var loader:FileLoader
    
    var body: some View {
        
        return ScrollView(.horizontal, showsIndicators: true){
            
            HStack{
                //.filter({$0.image != nil})
                ForEach(group.members){ x in
                    ThumbnailView(info: x,im: x.image,radius:3)
                        .onTapGesture {
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
    
    @ObservedObject var obj:ProgessWatcher<FileLoader>
    @ObservedObject var fLoader:FileLoader
    
    var body: some View {
        
        VStack{
                    Text("Loading \(fLoader.name)")
            Group {
                if obj.monitor.isDone {
                    Text("yay with loading")
                } else {
                    ProgressGroupView(monitor: obj.monitor)
                }
            }
                    
                    Button(action: {
                        self.obj.item.makeClusters()
                    }){
                        Text("Make Groups  \(fLoader.name)")
                    }
                    
                }
    }
    
    /*
    var body: some View {
        
       // let myGroups = obj.item
       // let details = obj.monitor.details
        
        return Group{
            
            if !obj.monitor.details.isEmpty{
                VStack{
                    Text("Loading \(fLoader.name)")
                    ProgressGroupView(monitor: obj.monitor)
                    Button(action: {
                        self.obj.item.makeClusters()
                    }){
                        Text("Make Groups  \(fLoader.name)")
                    }
                    
                }
            } else {
                VStack{
                    Text("Done loading  \(fLoader.name)")
                    
                    HStack{
                        if obj.item.isComputingCluster {
                            Circle().frame(width: 10, height: 10, alignment: .center).foregroundColor(.red)
                        } else {
                            Circle().frame(width: 10, height: 10, alignment: .center).foregroundColor(.green)
                        }
                        Group{
                            if (obj.item.groups.isEmpty){
                                Button(action: {
                                    self.fLoader.makeClusters()
                                }){
                                    Text("Make Groups \(fLoader.name)")
                                }
                            } else {
                                Slider(value: $obj.item.theshold, in: 1...40)
                            }
                        }
                    }
                    
                    if (!fLoader.groups.isEmpty){
                        
                        DetailView(loader: obj.item,
                                   info: obj.item.files[max(0,fLoader.selectIndex)],
                                   im: ImageFileResource(
                                    url: obj.item.files[max(0,fLoader.selectIndex)].info.path, maxDim: ImageFileResource.largeSize),
                                   radius:10)
                        List(obj.item.groups) { landmark in
                            GroupView(group: landmark, loader: self.fLoader).frame(height:ImageFileResource.thumbSize.height + 10)
                            
                        }
                            
                            .background(Color.red)
                        
                    } else {
                        Text("Just have files and no groups")
                        List(obj.item.files) { landmark in
                            HStack{
                                DetailView(loader: self.obj.item, info: landmark, im: landmark.image, radius: 3)
                                Text(landmark.key)
                                Text(landmark.key)
                            }
                        }
                        .background(Color.orange)
                    }
                }
                
            }
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    */
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        let foo = ProgessWatcher(item: FileLoader.empty)
        return ContentView(obj: foo,fLoader:foo.item)
    }
}
#endif
