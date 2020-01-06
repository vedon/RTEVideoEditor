//
//  RosyFilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import AVFoundation

class RosyFilter: FilterQuickLook {
    let id: String
    var computePipelineState: MTLComputePipelineState?
    var context: FilterSharedContext? {
        didSet {
           computePipelineState = nil
        }
    }
    var params: FilterParams?
    
    var quickLookDesc: String? {
        return "Rosy Filter"
    }
    
    init() {
        self.id = NSUUID().uuidString
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

extension RosyFilter: RTEFilterImp {
    var identifier: String {
        return self.id
    }
    
    func prepare() {
        if self.computePipelineState == nil {
            self.computePipelineState = makeRosyPipelineState()
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        guard let context = self.context,
            let commandQueue = context.commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
            let computePipelineState = self.computePipelineState else {
            
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        guard let (inputTexture, outputTexture, outputPixelBuffer) = context.makeInOutTexture(pixelBuffer) else {
            assertionFailure("Allocation Texture Failure")
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
