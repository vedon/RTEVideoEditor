//
//  RTERenderEffect.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import AVFoundation

class RTERenderEffect: RTEFilter {
    let context: RenderSharedContext
    var params: FilterParams?
    
    var name: String { return "" }
    var vertexFunc: String { return "vertexPassThrough" }
    var fragmentFunc: String { return "fragmentPassThrough" }
    var samplerImages: [String] { return [] }
    var quickLookDesc: String? { return "" }
    
    var transform = RendererTransform()
    private(set) var uniformBuffer: MTLBuffer!
    private(set) var vertexBuffer: MTLBuffer!
    private(set) var strengthBuffer: MTLBuffer!
    
    //Texture with source images loaded from files
    private var imageSamplerCache: [String: MTLTexture] = [:]
    
    lazy var pipelineDescriptor: MTLRenderPipelineDescriptor? = {
        guard let defaultLibrary = context.device.makeDefaultLibrary() else {
            assertionFailure("Invalid library")
            return nil
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = context.pixelFormat
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: vertexFunc)
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: fragmentFunc)
        return pipelineDescriptor
    }()
    
    lazy var pipelineState: MTLRenderPipelineState? = {
        guard let pipelineDescriptor = self.pipelineDescriptor else { return nil }
        return try? context.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }()
    
    lazy var renderPass: MTLRenderPassDescriptor = {
        var renderPassDescriptor = MTLRenderPassDescriptor.init()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return renderPassDescriptor
    }()
    
    lazy var sampler: MTLSamplerState? = {
        return RTESampler.clampToZero.makeWith(device: context.device)
    }()
    
    init(context: RenderSharedContext) {
        self.context = context
        vertexBuffer = context.device.makeBuffer(bytes: transform.quadVertices, length: transform.quadVertices.count * MemoryLayout<RTEVertex>.stride, options: [])
        vertexBuffer.label = "Vertex_buffer"
        
        uniformBuffer = context.device.makeBuffer(length: MemoryLayout<RTEUniforms>.stride, options: .storageModeShared)
        uniformBuffer.label = "Uniform_buffer"
        
        transform.drawableSize = context.drawableSize
        let uniform = uniformBuffer.contents().bindMemory(to: RTEUniforms.self, capacity: 1)
        uniform[0].mvp = transform.mvp
    }

    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {

        guard let inputTexture = context.textureFrom(pixelBuffer: pixelBuffer) else { return pixelBuffer }
        renderPass.colorAttachments[0].texture = inputTexture
        
        guard let commandBuffer = context.commandQueue?.makeCommandBuffer() else {
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        var imageSamplers: [MTLTexture] = []
        samplerImages.forEach { (name) in
            if imageSamplerCache[name] == nil {
                if  let texture = context.newTextureWith(fileName: name, commandBuffer: commandBuffer) {
                    imageSamplerCache[name] = texture
                }
            }
            imageSamplers.append(imageSamplerCache[name]!)
        }
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass),
            let pipelineState = self.pipelineState else {
            
            assertionFailure("Invalid Renderer Context")
            return pixelBuffer
        }
        
        commandEncoder.pushDebugGroup(name)
        commandEncoder.setRenderPipelineState(pipelineState)
        
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(RTEBufferIndexUniforms.rawValue))
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(RTEBufferIndexVertices.rawValue))
        
        commandEncoder.setFragmentTexture(inputTexture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        
        for (index, texture) in imageSamplers.enumerated() {
            commandEncoder.setFragmentTexture(texture, index: index + 1)
            commandEncoder.setFragmentSamplerState(sampler, index: index + 1)
        }
        
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.popDebugGroup()
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        return pixelBuffer
    }
    
    func prepare() {
        //Do nothing
    }
}
