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

protocol FilterParams {}

class RTEPixelBuffer {
    let renderGraph: RTERenderGraph
    let data: CVPixelBuffer
    
    init(renderGraph: RTERenderGraph, pixelBuffer: CVPixelBuffer) {
        self.renderGraph = renderGraph
        self.data = pixelBuffer
    }
    
    convenience init(pixelBuffer: CVPixelBuffer) {
        self.init(renderGraph: RTERenderGraph(), pixelBuffer: pixelBuffer)
    }
    
    @objc func debugQuickLookObject() -> Any? {
        return renderGraph.draw()
    }
}

protocol RTEFilter {
    var context: RenderSharedContext { get }
    var params: FilterParams? { get set }
    
    func render(pixelBuffer: RTEPixelBuffer) -> RTEPixelBuffer
    func prepare()
}


