//
//  RTERenderGraph.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/17.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation

struct RenderDescriptor {
    let name: String
}

struct RTERenderGraph {
    var descriptors: [RenderDescriptor]
    func draw() -> Any? {
        
        var descString: String = ""
        for (index, descriptor) in descriptors.enumerated() {
            if descString.count == 0 {
                descString.append(descriptor.name)
            } else {
                descString.append("\n")
                for _ in 0..<index {
                    descString.append(" ")
                }
                descString.append("-> \(descriptor.name)")
            }
        }
        
        return descString
    }
    
    init() {
        self.descriptors = []
    }
}
