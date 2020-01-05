//
//  FilterRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

struct FilterRendererContext {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue?
    let textureCache: CVMetalTextureCache?
    let pixelBufferPool: CVPixelBufferPool?
}

protocol FilterRenderer {
    var context: FilterRendererContext? { get set }
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    func prepare()
}
