//
//  SutroFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/11.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation

class SutroFilter: RTERenderEffect {
    override var name: String { return "SutroFilter" }
    
    override var fragmentFunc: String { return "sutroEffect" }
    
    override var samplerImages: [String] {
        return [
            "sutroCurves.png",
            "sutroEdgeBurn.pvr",
            "softLight.png",
            "sutroMetal.pvr",
            "blackOverlayMap.png",
        ]
    }
}
