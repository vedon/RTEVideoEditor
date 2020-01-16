//
//  RTEFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/8.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation
import UIKit

enum RTEFilterType: String, CaseIterable {
    case rosy
    case downsample
    case moon
    case sutro
    case rise
    case gaussian
    case canvas
    
    //The filter with lower priority will be apllied later
    var priority: Int {
        switch self {
        case .canvas: return 0
        default: return 1
        }
    }
}

protocol FilterParams {
}

protocol RTEFilter {
    var context: RenderSharedContext { get }
    var params: FilterParams? { get set }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer
    func prepare()
    
    var quickLookDesc: String? { get }
}

extension RTEFilter {
    var quickLookDesc: String? {
        return ""
    }
}

