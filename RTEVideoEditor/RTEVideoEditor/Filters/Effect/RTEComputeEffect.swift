//
//  RTEComputeEffect.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/13.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

class RTEComputeEffect: RTEFilter {
    let context: RenderSharedContext
    var params: FilterParams?
    
    var fragmentFunc: String { return "fragmentPassThrough" }
    var quickLookDesc: String? { return "" }
    
    var computePipelineState: MTLComputePipelineState? {
        var pipelineState: MTLComputePipelineState?
        let kernelFunction = context.device.makeDefaultLibrary()!.makeFunction(name: fragmentFunc)
        do {
            pipelineState = try context.device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            Logger.shared.warn("Could not create pipeline state: \(fragmentFunc)")
        }
        return pipelineState
    }
    
    init(context: RenderSharedContext) {
        self.context = context
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        return pixelBuffer
    }
    
    func prepare() {
        //Do nothing
    }
}
