//
//  FilterContext.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit

class RenderSharedContext {
    let device: MTLDevice
    let textureCache: CVMetalTextureCache
    let drawableSize: CGSize
    let pixelFormat: MTLPixelFormat
    
    private(set) var pixelBufferPool: RTEPixelBufferPool
    private lazy var textureLoader: MTKTextureLoader = {
        return MTKTextureLoader.init(device: device)
    }()
    
    lazy var commandQueue: MTLCommandQueue? = {
        return device.makeCommandQueue()
    }()
    
    lazy var coreImageContext: CIContext = {
        let coreImageContext = CIContext.init(mtlDevice: device)
        return coreImageContext
    }()
    
    init(device: MTLDevice, textureCache: CVMetalTextureCache, drawableSize: CGSize, pixelFormat: MTLPixelFormat) {
        self.device = device
        self.textureCache = textureCache
        self.drawableSize = drawableSize
        self.pixelFormat = pixelFormat
        self.pixelBufferPool = RTEPixelBufferPool()
    }
    
    func newTextureWith(fileName: String, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        guard let data = try? Data.init(contentsOf: URL(string: resourceURL.absoluteString + fileName)!) else {
            assertionFailure()
            return nil
        }
        
        if var ciImage = CIImage.init(data: data), let cgImage = coreImageContext.createCGImage(ciImage, from: ciImage.extent) {
            ciImage = ciImage.oriented(.downMirrored)
            
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
                                                                      width: cgImage.width,
                                                                      height: cgImage.height,
                                                                      mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.textureType = .type2D
            
            guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
            
            
            let destination = CIRenderDestination.init(mtlTexture: texture, commandBuffer: commandBuffer)
            let colorspace = CGColorSpaceCreateDeviceRGB();
            destination.colorSpace = colorspace
            destination.alphaMode = .premultiplied
            do {
                try coreImageContext.startTask(toRender: ciImage, to: destination)
            } catch  {
                assertionFailure(error.localizedDescription)
            }
            
            return texture
        }
        return nil
    }
    
    func newTextureFrom(image: UIImage, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard let cgImage = image.cgImage else {
            assertionFailure("Invalid Image")
            return nil
        }
        
        let ciImage = CIImage.init(cgImage: cgImage)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
                                                                  width: cgImage.width,
                                                                  height: cgImage.height,
                                                                  mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.textureType = .type2D
        
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        
        
        let destination = CIRenderDestination.init(mtlTexture: texture, commandBuffer: commandBuffer)
        let colorspace = CGColorSpaceCreateDeviceRGB();
        destination.colorSpace = colorspace
        destination.alphaMode = .premultiplied
        do {
            try coreImageContext.startTask(toRender: ciImage, to: destination)
        } catch  {
            assertionFailure(error.localizedDescription)
        }

        return texture
    }
    
    func textureFrom(pixelBuffer: CVPixelBuffer?) -> MTLTexture? {
        guard let pixelBuffer = pixelBuffer else {
            assertionFailure("Invalid PixelBuffer")
            return nil
        }
        return makeMTLTextureFromCVPixelBuffer(pixelBuffer, textureFormat: self.pixelFormat, cache: textureCache)
    }
    
    func newTextureFrom(pixelBuffer: CVPixelBuffer?, customSize: CGSize = .zero) -> (outputTexture: MTLTexture, outputPixelBuffer: CVPixelBuffer)? {
        guard let pixelBuffer = pixelBuffer else {
            assertionFailure("Invalid PixelBuffer")
            return nil
        }
        
        var newPixelBuffer: CVPixelBuffer?
        if customSize.equalTo(.zero) {
            newPixelBuffer = pixelBufferPool.newPixelBufferFrom(pixelBuffer: pixelBuffer)
        } else {
            newPixelBuffer = pixelBufferPool.newPixelBuffer(size: customSize, pixelFormat: CMFormatDescription.MediaSubType(rawValue: kCVPixelFormatType_32BGRA))
        }
        
        guard let outputPixelBuffer = newPixelBuffer else {
            assertionFailure("Allocation PixelBuffer Failure")
            return nil
        }
        
        guard let outputTexture = makeMTLTextureFromCVPixelBuffer(outputPixelBuffer, textureFormat: self.pixelFormat, cache: textureCache) else {
            assertionFailure("Allocation Texture Failure")
            return nil
        }
        
        return (outputTexture, outputPixelBuffer)
    }
}
