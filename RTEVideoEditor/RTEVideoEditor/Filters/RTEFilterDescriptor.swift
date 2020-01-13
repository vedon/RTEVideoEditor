//
//  FilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

struct RTEFilterDescriptor {
    let identifier: String
    let type: RTEFilterType
    
    init(type: RTEFilterType) {
        self.identifier = NSUUID().uuidString
        self.type = type
    }
}
