//
//  MetalRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/15.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import Metal
import AVFoundation

struct RendererDescriptor {
    let pixelFormat: MTLPixelFormat
    
    var loadAction: MTLLoadAction = .clear
    var storeAction: MTLStoreAction = .store
    var clearColor: MTLClearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
}

class MetalRenderer {
    let device: MTLDevice
    var descriptor: RendererDescriptor
    var transform: RendererTransform = RendererTransform.init()
    
    private let sampler: MTLSamplerState?
    private var uniformBuffer: MTLBuffer!
    private var vertexBuffer: MTLBuffer!
    private let commandQueue: MTLCommandQueue?
    
    lazy var pipelineState: MTLRenderPipelineState? = {
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            assertionFailure("Invalid library")
            return nil
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = descriptor.pixelFormat
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")
    
        let pipelineState: MTLRenderPipelineState?
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor:
                pipelineDescriptor)
        } catch {
            fatalError("Unable to create preview Metal view pipeline state. (\(error))")
        }
        return pipelineState
    }()
    
    
    lazy var renderPassDescriptor: MTLRenderPassDescriptor = {
       let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = descriptor.loadAction
        renderPassDescriptor.colorAttachments[0].storeAction = descriptor.storeAction
        renderPassDescriptor.colorAttachments[0].clearColor = descriptor.clearColor
        return renderPassDescriptor
    }()
    
    init(device: MTLDevice, descriptor: RendererDescriptor) {
        self.device = device
        self.descriptor = descriptor
        self.commandQueue = device.makeCommandQueue()
        self.sampler = RTESampler.clampToEdge.makeWith(device: device)
        setupTransform()
    }
    
    func start(toRender inputTexture: MTLTexture, toDestination drawableTexture: MTLTexture, debugGroup: String = "") {
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
            let pipelineState = self.pipelineState else {
            assertionFailure("Invalid Renderer Context")
            return
        }
        
        transform.videoTextureSize = CGSize(width: CGFloat(inputTexture.width),
                                                       height: CGFloat(inputTexture.height))
        
        transform.drawableSize = CGSize(width: CGFloat(drawableTexture.width),
                                                   height: CGFloat(drawableTexture.height))
        
        let uniform = uniformBuffer.contents().bindMemory(to: RTEUniforms.self, capacity: 1)
        uniform[0].mvp = transform.mvp
        
        renderPassDescriptor.colorAttachments[0].texture = drawableTexture
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            assertionFailure("Invalid command encoder")
            return
        }
        
        commandEncoder.pushDebugGroup(debugGroup)
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(RTEBufferIndexUniforms.rawValue))
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(RTEBufferIndexUniforms.rawValue))
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(RTEBufferIndexVertices.rawValue))
        
        let viewport = MTLViewport(originX: 0.0,
                                   originY: 0.0,
                                   width: Double(transform.drawableSize.width),
                                   height: Double(transform.drawableSize.height),
                                   znear: -1,
                                   zfar: 1)
        commandEncoder.setViewport(viewport)
        commandEncoder.setFragmentTexture(inputTexture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.popDebugGroup()
        commandEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    private func setupTransform() {
        //For more memory managament, go to http://metalkit.org/2017/04/30/working-with-memory-in-metal.html
        vertexBuffer = device.makeBuffer(bytes: transform.quadVertices,
                                         length: transform.quadVertices.count * MemoryLayout<RTEVertex>.stride,
                                         options: [])
        vertexBuffer.label = "Vertex_buffer"
        
        uniformBuffer = device.makeBuffer(length: MemoryLayout<RTEUniforms>.stride, options: .storageModeShared)
        uniformBuffer.label = "Uniform_buffer"
    }
}
