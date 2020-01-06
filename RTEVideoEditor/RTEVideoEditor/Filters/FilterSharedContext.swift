//
//  FilterContext.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

struct FilterSharedContext {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue?
    let textureCache: CVMetalTextureCache?
    let pixelBufferPool: CVPixelBufferPool?
    let drawableSize: CGSize
    
    func makeInOutTexture(_ inPixelBuffer: CVPixelBuffer) -> (inTexture: MTLTexture, outTexture: MTLTexture, outPixelBuffer: CVPixelBuffer)? {
        
        guard let pixelBufferPool = self.pixelBufferPool else { return nil }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &newPixelBuffer)
        
        guard let outputPixelBuffer = newPixelBuffer else {
            assertionFailure("Allocation PixelBuffer Failure")
            return nil
        }
        
        guard let inputTexture = makeTextureFromCVPixelBuffer(inPixelBuffer,
                                                              textureFormat: .bgra8Unorm,
                                                              cache: textureCache),
            
            let outputTexture = makeTextureFromCVPixelBuffer(outputPixelBuffer,
                                                             textureFormat: .bgra8Unorm,
                                                             cache: textureCache) else {
                                                                
            assertionFailure("Allocation Texture Failure")
            return nil
        }
        
        return (inputTexture, outputTexture, outputPixelBuffer)
    }
}
