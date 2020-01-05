//
//  CVPixelBufferPoolUtil.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

func makeTextureFromCVPixelBuffer(_ pixelBuffer: CVPixelBuffer?, textureFormat: MTLPixelFormat, cache: CVMetalTextureCache?) -> MTLTexture? {
    
    guard let pixelBuffer = pixelBuffer, let textureCache = cache else { return nil }
    let isPlanar = CVPixelBufferIsPlanar(pixelBuffer)
    let width = isPlanar ? CVPixelBufferGetWidthOfPlane(pixelBuffer, 0) : CVPixelBufferGetWidth(pixelBuffer)
    let height = isPlanar ? CVPixelBufferGetHeightOfPlane(pixelBuffer, 0) : CVPixelBufferGetHeight(pixelBuffer)
    
    var cvTextureOut: CVMetalTexture?
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
    
    guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
        CVMetalTextureCacheFlush(textureCache, 0)
        
        return nil
    }
    
    return texture
}

func allocateOutputBufferPool(pixelFormat: CMFormatDescription.MediaSubType, width: Int, height: Int, bufferCountHint: Int) -> CVPixelBufferPool? {
    //let formatDesc = try? CMFormatDescription.init(mediaType: .audio, mediaSubType: .pixelFormat_32BGRA)
    var outputPixelBufferPool: CVPixelBufferPool? = nil
    let pixelBufferAttributes: NSDictionary = [kCVPixelBufferPixelFormatTypeKey: pixelFormat,
                                              kCVPixelBufferWidthKey: width,
                                              kCVPixelBufferHeightKey: height,
                                              kCVPixelFormatOpenGLESCompatibility: true,
                                              kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
    
    let poolAttributes: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: bufferCountHint]
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes, pixelBufferAttributes, &outputPixelBufferPool)
    return outputPixelBufferPool
}

private func createPixelBufferPool(_ width: Int32, _ height: Int32, _ pixelFormat: OSType, _ maxBufferCount: Int32) -> CVPixelBufferPool? {
    var outputPool: CVPixelBufferPool? = nil
    let sourcePixelBufferOptions: NSDictionary = [kCVPixelBufferPixelFormatTypeKey: pixelFormat,
                                                  kCVPixelBufferWidthKey: width,
                                                  kCVPixelBufferHeightKey: height,
                                                  kCVPixelFormatOpenGLESCompatibility: true,
                                                  kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
    
    let pixelBufferPoolOptions: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: maxBufferCount]
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions, sourcePixelBufferOptions, &outputPool)
    return outputPool
}

func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) ->(
    outputBufferPool: CVPixelBufferPool?,
    outputColorSpace: CGColorSpace?,
    outputFormatDescription: CMFormatDescription?) {
        
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        if inputMediaSubType != kCVPixelFormatType_32BGRA {
            assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
            return (nil, nil, nil)
        }
        
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]
            
            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]
                
                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }
                
                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }
                
                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }
            
            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }
        
        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
            return (nil, nil, nil)
        }
        
        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)
        
        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescriptionOut: &outputFormatDescription)
        }
        pixelBuffer = nil
        
        return (pixelBufferPool, cgColorSpace, outputFormatDescription)
}

private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
    var pixelBuffers = [CVPixelBuffer]()
    var error: CVReturn = kCVReturnSuccess
    let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
    var pixelBuffer: CVPixelBuffer?
    while error == kCVReturnSuccess {
        error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            pixelBuffers.append(pixelBuffer)
        }
        pixelBuffer = nil
    }
    pixelBuffers.removeAll()
}


