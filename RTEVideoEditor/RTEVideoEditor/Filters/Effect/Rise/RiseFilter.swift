//
//  RiseFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation

class RiseFilter: RTERenderEffect {
    override var name: String { return "RiseFilter" }
    
    override var fragmentFunc: String { return "riseEffect" }
    
    override var samplerImages: [String] {
        return [
            "blackboard.png",
            "riseMap.png",
            "overlayMap.png"
        ]
    }
}
