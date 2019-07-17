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
    @ObjectBinding var im:ImageFileResource
    let radius:CGFloat
    
    var body: some View {
        Image(nsImage: im.image)
                .resizable()
                .frame(width: im.image.size.width , height: im.image.size.height ).padding()
            .background(info.background(rad: radius))
    }
    
}







