//
//  FilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

enum RTEFilterType: CaseIterable {
    case rosy
    case downsample
}

struct RTEFilter {
    let identifier: String
    let type: RTEFilterType
    
    init(type: RTEFilterType) {
        self.identifier = NSUUID().uuidString
        self.type = type
    }
}

protocol FilterParams {
}

protocol RTEFilterImp {
    var context: FilterSharedContext? { get set }
    var params: FilterParams? { get set }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer
    func prepare()
}

protocol FilterQuickLook {
    var quickLookDesc: String? { get }
}
