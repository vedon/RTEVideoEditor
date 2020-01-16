//
//  CanvasFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation
import MetalPerformanceShaders

struct CanvasParams: FilterParams {
    private(set) var blurRadius: Float = 0.0
    var scale: Float = 1.0
    var blurProgress: Float = 0.0 {
        didSet {
            self.blurRadius = 20 * blurProgress
        }
    }
}

class CanvasFilter {
    var params: FilterParams?
    let context: RenderSharedContext
    
    lazy var gaussianFilter: GaussianFilter = {
        let gaussianFilter = GaussianFilter.init(context: context)
        gaussianFilter.renderer.transform.contentMode = .aspectFill
        return gaussianFilter
    }()
    
    lazy var renderer: MetalRenderer = {
        var descriptor = RendererDescriptor(pixelFormat: context.pixelFormat)
        descriptor.loadAction = .load
        descriptor.storeAction = .store
        return MetalRenderer(device: context.device, descriptor: descriptor)
    }()
    
    init(context: RenderSharedContext) {
        self.context = context
    }
}

extension CanvasFilter: RTEFilter {
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer),
            let (drawableTexture, outputPixelBuffer) = context.newTextureFrom(pixelBuffer: pixelBuffer, customSize: context.drawableSize) else {
            return pixelBuffer
        }
        
        self.gaussianFilter.render(pixelBuffer: pixelBuffer, toDestinate: drawableTexture)
        renderer.start(toRender: inputTexture, toDestination: drawableTexture, debugGroup: "Draw canvas")

        return outputPixelBuffer
    }
    
    func prepare() {
        self.gaussianFilter.params = self.params
        self.gaussianFilter.prepare()
    }
}
