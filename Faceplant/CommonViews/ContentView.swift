import SwiftUI
import Combine


extension ACFileStatus {
    func background(rad:CGFloat)-> some View{
        
        if isKeeper {
            return Color.blue.cornerRadius(rad)
        } else {
            return Color.gray.cornerRadius(rad)
        }
    }
}

/*
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
 
 */


#if os(OSX)



func makeScale(path:String,maxDim:CGFloat = 300)->NSImage?{
    
     let thumbSize = NSSize(width: 128, height: 128)
     let largeSize:CGFloat = 600
    
    let url = URL(fileURLWithPath: path)
    
    print("making thumbnail: \(path)")
    if let im = NSImage(contentsOf: url){
        let longest = max(im.size.height,im.size.width)
        let scale = maxDim/longest
        let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
        let small = NSImage(size: size)
        let fromRect = NSRect(x: 0, y: 0, width:im.size.width, height: im.size.height)
        
        small.lockFocus()
        im.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height), from: fromRect, operation: .copy, fraction: 1)
        small.unlockFocus()
        
        return  small
        
    }
    return nil
}

#else



func makeScale()->OSImage?{
    print("making thumbnail: \(self.url) size \(maxDim)")
    if let im = UIImage(contentsOfFile: self.url){
        let longest = max(im.size.height,im.size.width)
        let scale = maxDim/longest
        let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return   renderer.image { (context) in
            im.draw(in: CGRect(origin: .zero, size: size))
        }
        
    }
    return nil
}

#endif



fileprivate  let imagequeue = DispatchQueue(label: "thumbnailqueue", qos: .userInitiated, attributes:  [], autoreleaseFrequency: .workItem, target: nil)

class ImageLoader: ObservableObject {
    var didChange = PassthroughSubject<OSImage, Never>()
    var maxDim:CGFloat = 200
    
    var data = OSImage(named: "empty.jpeg")! {
        didSet {
            didChange.send(data)
        }
    }

    init(urlString:String) {
        let path = URL(fileURLWithPath: urlString)
        
        
        imagequeue.async {
            /*[weak self ] in
            guard let s = self else {
                print("quit image loader too early")
                return
            }
 */
            let s = self
            
               
               print("making thumbnail: \(path)")
               if let im = NSImage(contentsOf: path){
                   let longest = max(im.size.height,im.size.width)
                
                
                let scale = s.maxDim/longest
                   let size = CGSize(width:im.size.width*scale,height: im.size.height*scale)
                   let small = NSImage(size: size)
                   let fromRect = NSRect(x: 0, y: 0, width:im.size.width, height: im.size.height)
                   
                   small.lockFocus()
                   im.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height), from: fromRect, operation: .copy, fraction: 1)
                   small.unlockFocus()
         
                
                DispatchQueue.main.async {
                    /*
                     [weak self ] in
                    
                    guard let s = self else {
                                  print("quit image loader too early")
                                  return
                              }
                    */
                    self.data = small
                }
                   
               }
            
        }
 
    }
}

struct ImageView: View {
    @ObservedObject var imageLoader:ImageLoader
    @State var image:OSImage = OSImage(named: "empty.jpeg")!

    init(withURL url:String) {
        imageLoader = ImageLoader(urlString:url)
    }

    var body: some View {
        VStack {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
               // .frame(width:100, height:100)
        }.onReceive(imageLoader.didChange) { data in
            self.image =  data
        }
    }
}

struct GroupView : View {
    
    @State var group:ACFileGroup
    let files:[FileInfo:ACFileStatus]
    
    var body: some View {
        
        let items = group.members.compactMap{ files[$0]}
        //let resources:[(status:ACFileStatus,resource:ImageFileResource)] = items.compactMap{($0,ImageFileResource(url: $0.info.path, maxDim: 50))}
        //let im:OSImage = items[0].image.image
      
        return
           
                
           
            
            HStack{
                Spacer().background(Color.blue.cornerRadius(4))
                Text("count \(items.count) and \(self.files.count)")
                 ScrollView(.horizontal, showsIndicators: true){
                ForEach(items){ x in
                    ImageView(withURL: x.info.path)
                    }
                    
                }
                Spacer()
            }
        }
        
    }
    


struct ContentView : View {
    @ObservedObject var model: FileLoaderModel
    
    var body: some View {
        let range:ClosedRange<Double> =  1...25
        let twoDecimalPlaces = String(format: "%.2f", Float(model.threshold))
        let lookup = model.model?.files ?? [:]
       // let status = model.monitor.details
        
        return  VStack{
            Text("Threshold \(twoDecimalPlaces)")
           
            Slider(value: $model.threshold, in:range)
            ForEach(model.monitor.details,id: \.name){ x in
                Text(x.name)
                
            }
            // ScrollView(.vertical, showsIndicators: true){
                List(model.groups, id: \.id) { x in
                    
                    GroupView(group: x,files: lookup)
                    
                }
           // }
        }
    }
}

/*
 #if DEBUG
 struct ContentView_Previews : PreviewProvider {
 static var previews: some View {
 let foo = ProgessWatcher(item: FileLoader.empty)
 return ContentView(obj: foo,fLoader:foo.item)
 }
 }
 #endif
 */
