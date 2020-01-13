//
//  CanvasFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/13.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation
import MetalPerformanceShaders

class CanvasFilter {
    var params: FilterParams?
    let context: RenderSharedContext
    
    private var gaussianFilter: MPSImageGaussianBlur?
    
    init(context: RenderSharedContext) {
        self.context = context
        
    }
}

extension CanvasFilter: RTEFilter {
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer() else {
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        
        
        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer),
            let (outputTexture, outputPixelBuffer) = context.newTextureFrom(pixelBuffer: pixelBuffer, customSize: context.drawableSize) else {
            return pixelBuffer
        }
        
        commandBuffer.commit()
        
        return pixelBuffer
    }
    
    func prepare() {
        if self.gaussianFilter == nil {
            self.gaussianFilter = MPSImageGaussianBlur.init(device: context.device, sigma: 1.0)
            self.gaussianFilter?.sigma
        }
    }
}
