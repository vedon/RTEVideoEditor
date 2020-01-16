//
//  RTEPixelBufferPool.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

class RTEPixelBufferPool {
    private var pixelBufferPools: [String: CVPixelBufferPool] = [:]
    
    func newPixelBuffer(size: CGSize, pixelFormat: CMFormatDescription.MediaSubType) -> CVPixelBuffer? {
        var pool = pixelBufferPools[size.stringDesc]
        if pool == nil {
            let newPool = allocateOutputBufferPool(pixelFormat: pixelFormat,
                                            width: Int(size.width),
                                            height: Int(size.height),
                                            bufferCountHint: 3)
            pixelBufferPools[size.stringDesc] = newPool
            pool = newPool
        }
        
        guard let pixelBufferPool = pool else { return nil }
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &newPixelBuffer)
        guard let outputPixelBuffer = newPixelBuffer else {
            assertionFailure("Allocation PixelBuffer Failure")
            return nil
        }
        return outputPixelBuffer
    }
    
    func newPixelBufferFrom(pixelBuffer: CVPixelBuffer, copy: Bool = false) -> CVPixelBuffer? {
        let pixelFormat = CMFormatDescription.MediaSubType(rawValue: CVPixelBufferGetPixelFormatType(pixelBuffer))
        
        let size = CGSize.init(width: CVPixelBufferGetWidth(pixelBuffer),
                               height: CVPixelBufferGetHeight(pixelBuffer))
        
        let newPixelBuffer = self.newPixelBuffer(size: size, pixelFormat: pixelFormat)
        
        if copy, let newPixelBuffer = newPixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferLockBaseAddress(newPixelBuffer, .readOnly)
            
            if let dest = CVPixelBufferGetBaseAddress(newPixelBuffer),
                let source = CVPixelBufferGetBaseAddress(pixelBuffer) {
                
                let size = CVPixelBufferGetDataSize(pixelBuffer)
                memcpy(dest, source, size)
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(newPixelBuffer, .readOnly)
        }
        return newPixelBuffer
    }
    
    deinit {
        Logger.shared.info("RTEPixelBufferPool deinit")
    }
}

extension CGSize {
    var stringDesc: String {
        return "\(self.width)/\(self.height)"
    }
}
