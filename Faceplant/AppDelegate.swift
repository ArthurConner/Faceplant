//
//  AppDelegate.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/8/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        
        
        /*
        let mymont = ProgessWatcher(item: FileLoader.empty)
        let cv = ContentView(obj: mymont, fLoader:FileLoader.empty)
        let monitor = mymont.monitor
        
        let k1 = "adding files"
        monitor.add(key: k1, name: k1,total:1)
        DispatchQueue.global(qos: .userInitiated).async {
            
            //let path = "/Volumes/Zoetrope/images"
            
            let path = "/Volumes/Zoetrope/images/2018/08/Keeper"
            
            let loader = FileLoader(recursive:path, kinds: [".JPG"], isImage: true,loader: monitor,name:"Status.json")
            
            loader.save()
            monitor.update(key: k1, amount: 1)
          
            
            monitor.finish(key: k1)
            DispatchQueue.main.async {
                cv.obj.item = loader
                cv.obj.item.loader = cv.obj.monitor
                if loader.groups.isEmpty {
                    loader.makeClusters()
                }
               cv.obj.item.loader = nil
            }
        }
 */
        
        let cv = ContentView()
        window.contentView = NSHostingView(rootView: cv)
        window.makeKeyAndOrderFront(nil)

    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}


