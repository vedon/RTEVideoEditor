//
//  MoonFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/7.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation
import UIKit
import CoreImage

class MoonFilter: RTERenderEffect {
    override var name: String { return "MoonFilter" }
    
    override var fragmentFunc: String { return "moonEffect" }
    
    override var samplerImages: [String] {
        return [
            "bw_curves1.png",
            "bw_curves2.png",
        ]
    }
}
