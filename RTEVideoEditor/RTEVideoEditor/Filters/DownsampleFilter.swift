//
//  DownsampleFilter.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation
import MetalKit
import MetalPerformanceShaders

class DownsampleFilter {
    let id: String = NSUUID().uuidString
    var context: FilterSharedContext?
    var params: FilterParams?
    
    private var lanczos: MPSImageLanczosScale?
    
    func downsampleSizeForPixelBuffer(_ pixelBuffer: CVPixelBuffer, drawableSize: CGSize) -> MPSScaleTransform {
        let size = CGSize.init(width: CVPixelBufferGetWidth(pixelBuffer),
                               height: CVPixelBufferGetHeight(pixelBuffer))
        return downsample(from: size, to: drawableSize, mode: .scaleAspectFit)
    }
    
    private func downsample(from inSize: CGSize, to outSize: CGSize, mode: UIView.ContentMode) -> MPSScaleTransform {
        var scaleX: Double
        var scaleY: Double
        switch mode {
        case .scaleToFill:
            scaleX = Double(outSize.width)  / Double(inSize.width)
            scaleY = Double(outSize.height) / Double(inSize.height)
        case .scaleAspectFill:
            scaleX = Double(outSize.width)  / Double(inSize.width)
            scaleY = Double(outSize.height) / Double(inSize.height)
            if scaleX > scaleY {
                scaleY = scaleX
            } else {
                scaleX = scaleY
            }
        case .scaleAspectFit:
            scaleX = Double(outSize.width)  / Double(inSize.width)
            scaleY = Double(outSize.height) / Double(inSize.height)
            if scaleX > scaleY {
                scaleX = scaleY
            } else {
                scaleY = scaleX
            }
        default:
            scaleX = 1
            scaleY = 1
        }
        
        let translateX: Double
        let translateY: Double
        switch mode {
        case .center, .scaleAspectFill, .scaleToFill:
            translateX = (Double(outSize.width)  - Double(inSize.width)  * scaleX) / 2
            translateY = (Double(outSize.height) - Double(inSize.height) * scaleY) / 2
        case .scaleAspectFit:
            translateX = 0
            translateY = 0
        default:
            fatalError("Not support")
        }

        return MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
    }
}

extension DownsampleFilter: RTEFilterImp {
    var identifier: String { return self.id }
    
    func prepare() {
        guard let device = context?.device else {
            assertionFailure("Invalid device")
            return
        }
        
        if lanczos == nil {
            lanczos = MPSImageLanczosScale.init(device: device)
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        guard let context = self.context,
            let commandQueue = context.commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer() else {
            
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        guard let (inputTexture, outputTexture, outputPixelBuffer) = context.makeInOutTexture(pixelBuffer) else {
            return pixelBuffer
        }
        
        var transform = downsampleSizeForPixelBuffer(pixelBuffer, drawableSize: context.drawableSize)
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) in
            lanczos?.scaleTransform = transformPtr
            lanczos?.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: outputTexture)
        }
        commandBuffer.commit()
        
        return outputPixelBuffer
    }
}
