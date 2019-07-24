//
//  SceneDelegate.swift
//  planter
//
//  Created by Arthur Conner on 7/9/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import UIKit
import SwiftUI
import Vision

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
 
            //loader.process()
            
            /*
 
             let other = FileLoader(recursive: "/Users/arthurconner/Downloads/Mertreat imported", kinds: [".JPG"], isImage: true)
             
             other.save()
             
             let loader = FileLoader("/Users/arthurconner/Downloads/Mertreat 2018", kinds: [".JPG"], isImage: true)
             .exclude(other: other)
             
             loader.save()
            
            let loader = FileLoader("/Users/arthurconner/Downloads/Mertreat 2018", kinds: [".JPG"], isImage: true)
            */
            
           //
            // .exclude(other: other)
         
           // let loader = FileLoader(recursive:"/Users/arthurconner/Downloads", kinds: [".JPG",".png"], isImage: true)
            
            let blankLoader = FileLoader.empty
            
            /*
 let monitor = ProgressMonitor()
            loader.save()
            print("about to process")
            
            let nl = loader.search(term
             let mymont = ProgessWatcher(item: FileLoader(flat:"/Volumes/Zoetrope/Keeper", kinds: [".JPG"], isImage: true,loader: nil))
             return ContentView(obj:mymont): "child")
            nl.makeClusters()
           */
            let mymont = ProgessWatcher(item: blankLoader)
            let cv = ContentView(obj: mymont)
            let monitor = mymont.monitor
            window.rootViewController = UIHostingController(rootView:cv )
            let k1 = "adding files"
            monitor.add(key: k1, name: k1,total:3)
            DispatchQueue.global(qos: .userInitiated).async {
                let other = FileLoader(flat: "/Users/arthurconner/Downloads/Mertreat imported", kinds: [".JPG"], isImage: true,loader: monitor)
                monitor.update(key: k1, amount: 1)
                let loader = FileLoader(recursive:"/Users/arthurconner/Downloads/Mertreat 2018", kinds: [".JPG"], isImage: true,loader: monitor)
                monitor.update(key: k1, amount: 1)
                loader.save()
                other.save()
                monitor.finish(key: k1)
                DispatchQueue.main.async {
                    cv.obj.item = loader.exclude(other: other)
                   
                    cv.obj.item.loader = cv.obj.monitor
                    cv.obj.item.name = "excludeMer.JSON"
                    cv.obj.item.makeClusters()
                    //cv.obj.item.loader = nil
                }
                
                
            }
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

