//
//  RosyFilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import AVFoundation

class RosyFilter: RTEComputeEffect {
    override var fragmentFunc: String { return "rosyEffect" }
    
    override func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        let pixelBuffer = super.render(pixelBuffer: pixelBuffer)
        
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
            let computePipelineState = self.computePipelineState else {
            
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer),
            let (outputTexture, outputPixelBuffer) = context.newTextureFrom(pixelBuffer: pixelBuffer) else {
            return pixelBuffer
        }
        
        commandEncoder.label = "Rosy"
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)
        
        let width = computePipelineState.threadExecutionWidth
        let height = computePipelineState.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + width - 1) / width,
                                          height: (inputTexture.height + height - 1) / height,
                                          depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.commit()

        return outputPixelBuffer
    }
}
