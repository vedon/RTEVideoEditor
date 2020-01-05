//
//  RosyFilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

class RosyFilterRenderer {
    var computePipelineState: MTLComputePipelineState?
    var context: FilterRendererContext? {
        didSet {
           computePipelineState = nil
        }
    }
    
    private func makeRosyPipelineState() -> MTLComputePipelineState? {
        var pipelineState: MTLComputePipelineState?
        let kernelFunction = context?.device.makeDefaultLibrary()!.makeFunction(name: "rosyEffect")
        do {
            pipelineState = try context?.device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            print("Could not create pipeline state: \(error)")
        }
        return pipelineState
    }
}

extension RosyFilterRenderer: FilterRenderer {
    func prepare() {
        if self.computePipelineState == nil {
            self.computePipelineState = makeRosyPipelineState()
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let context = self.context,
            let commandQueue = context.commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
            let computePipelineState = self.computePipelineState,
            let pixelBufferPool = context.pixelBufferPool  else {
            
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &newPixelBuffer)
        
        guard let outputPixelBuffer = newPixelBuffer else {
            assertionFailure("Allocation failure")
            return pixelBuffer
        }
        guard let inputTexture = makeTextureFromCVPixelBuffer(pixelBuffer, textureFormat: .bgra8Unorm, cache: context.textureCache),
            let outputTexture = makeTextureFromCVPixelBuffer(outputPixelBuffer, textureFormat: .bgra8Unorm, cache: context.textureCache) else {
                return nil
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
