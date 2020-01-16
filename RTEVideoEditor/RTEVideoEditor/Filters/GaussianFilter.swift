//
//  GaussianFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import MetalPerformanceShaders
import AVFoundation

class GaussianFilter {
    private var gaussianFilter: MPSImageGaussianBlur?
    var params: FilterParams?
    let context: RenderSharedContext
    
    lazy var renderer: MetalRenderer = {
        let descriptor = RendererDescriptor(pixelFormat: context.pixelFormat)
        let renderer = MetalRenderer(device: context.device, descriptor: descriptor)
        renderer.transform.contentMode = .aspectFit
        return renderer
    }()
    
    init(context: RenderSharedContext) {
        self.context = context
    }
    
    func render(pixelBuffer: CVPixelBuffer, toDestinate drawableTexture: MTLTexture) {
        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer) else {
            assertionFailure("Invalid Renderer Context")
            return
        }
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer(),
            let (gaussiamTexture, _) = context.newTextureFrom(pixelBuffer: pixelBuffer) else {
            assertionFailure("Invalid Renderer Context")
            return
        }
        gaussianFilter?.encode(commandBuffer: commandBuffer,
                              sourceTexture: inputTexture,
                              destinationTexture: gaussiamTexture)
        commandBuffer.commit()
        
        renderer.start(toRender: gaussiamTexture, toDestination: drawableTexture, debugGroup: "Gaussian")
    }
}

extension GaussianFilter: RTEFilter {
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        var pixelBuffer = pixelBuffer

        if self.gaussianFilter != nil {
            guard let (drawableTexture, outputPixelBuffer) = context.newTextureFrom(pixelBuffer: pixelBuffer) else {
                return pixelBuffer
            }
            
            render(pixelBuffer: pixelBuffer, toDestinate: drawableTexture)
            pixelBuffer = outputPixelBuffer
        }
        
        return pixelBuffer
    }
    
    func prepare() {
        if let params = self.params as? CanvasParams {
            if gaussianFilter == nil || gaussianFilter?.sigma != params.blurRadius {
                gaussianFilter = MPSImageGaussianBlur(device: context.device,
                sigma: params.blurRadius)
            }
        }
    }
}
