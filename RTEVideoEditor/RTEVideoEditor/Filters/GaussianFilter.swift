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
    
    func render(pixelBuffer: RTEPixelBuffer, toDestinate drawableTexture: MTLTexture) -> [RenderDescriptor] {
        var graph = RTERenderGraph()
        
        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer.data),
            let commandBuffer = context.commandQueue?.makeCommandBuffer() else {
            assertionFailure("Invalid Renderer Context")
            return graph.descriptors
        }
        
        if inputTexture.width == drawableTexture.width, inputTexture.height == drawableTexture.height {
            gaussianFilter?.encode(commandBuffer: commandBuffer,
                                  sourceTexture: inputTexture,
                                  destinationTexture: drawableTexture)
            commandBuffer.commit()
            
            graph.descriptors.append(RenderDescriptor(name: "Render_Gaussian_Texture"))
            return graph.descriptors
            
        } else {
            
            guard let (gaussiamTexture, _) = context.newTextureFrom(pixelBuffer: pixelBuffer.data) else {
                assertionFailure("Invalid Renderer Context")
                return graph.descriptors
            }
            
            gaussianFilter?.encode(commandBuffer: commandBuffer,
                                  sourceTexture: inputTexture,
                                  destinationTexture: gaussiamTexture)
            commandBuffer.commit()
            graph.descriptors.append(RenderDescriptor(name: "Render_Gaussian_Texture"))
            
            let descriptors = renderer.start(toRender: gaussiamTexture,
                                             toDestination: drawableTexture,
                                             debugGroup: "Aspect_Fill")
            graph.descriptors.append(contentsOf: descriptors)
            return graph.descriptors
            
        }
    }
}

extension GaussianFilter: RTEFilter {
    func render(pixelBuffer: RTEPixelBuffer) -> RTEPixelBuffer {
        var pixelBuffer = pixelBuffer

        if self.gaussianFilter != nil {
            guard let (drawableTexture, outputPixelBuffer) = context.newTextureFrom(pixelBuffer: pixelBuffer.data) else {
                return pixelBuffer
            }
            
            var graph = pixelBuffer.renderGraph
            let descriptors = render(pixelBuffer: pixelBuffer, toDestinate: drawableTexture)
            graph.descriptors.append(contentsOf: descriptors)
            
            pixelBuffer = RTEPixelBuffer(renderGraph: graph, pixelBuffer: outputPixelBuffer)
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
