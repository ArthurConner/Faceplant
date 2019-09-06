//
//  ProgressGroupView.swift
//  Faceplant
//
//  Created by Arthur Conner on 7/15/19.
//  Copyright © 2019 Arthur Conner. All rights reserved.
//

import SwiftUI

struct ProgressGroupView : View {
    @ObservedObject var monitor:ProgressMonitor
    var body: some View {
        
        VStack{
            ForEach( monitor.details, id: \.name) { x in
                Text("\(x.name):\t [\(x.distance) out of \(x.total)]")
            }
        }
    
    }
}

#if DEBUG
struct ProgressGroupView_Previews : PreviewProvider {
    static var previews: some View {
        let moni = ProgressMonitor()
        moni.add(key: "only", name: "one", total: 100)
        moni.add(key: "other", name: "two", total: 100)
        moni.update(key: "only", amount: 50)
        
        return ProgressGroupView(monitor: moni)
    }
}
#endif
