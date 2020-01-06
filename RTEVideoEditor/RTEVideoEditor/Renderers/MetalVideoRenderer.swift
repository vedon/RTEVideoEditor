//
//  MetalVideoRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import AVFoundation

class MetalVideoRenderer {
    let device: MTLDevice
    let filterManager: FilterManager
    var transform: RendererTransform = RendererTransform.init()
    
    private var sampler: MTLSamplerState?
    private var commandQueue: MTLCommandQueue?
    private var textureCache: CVMetalTextureCache?
    private var pipelineState: MTLRenderPipelineState!
    private var renderPassDescriptor: MTLRenderPassDescriptor?
    private(set) var pixelFormat: MTLPixelFormat = .bgra8Unorm

    private var uniformBuffer: MTLBuffer!
    private var quadVertexBuffer: MTLBuffer!
    private var curPixelBuffer: CVPixelBuffer?
    
    private let inFlightSemaphore = DispatchSemaphore(value: 1)
    
    private let syncQueue: DispatchQueue
    
    private var outputFormatDescription: CMFormatDescription?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private var filterContext: FilterSharedContext?
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        
        self.device = device
        
        self.filterManager = FilterManager()
        
        self.syncQueue = DispatchQueue(label: "Metal Renderer Sync Queue",
                                       qos: .`default`,
                                       attributes: [],
                                       autoreleaseFrequency: .workItem)
        
        setupTextureCache()
        
        setupPipelineState()
        
        setupTransform()
        
        setupRenderPassDescriptor()
        
        commandQueue = device.makeCommandQueue()
    }
    
    private func setupPipelineState() {
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            assertionFailure("Invalid library")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create preview Metal view pipeline state. (\(error))")
        }
    }
    
    private func setupTextureCache() {
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            assertionFailure("Unable to allocate texture cache")
        }
    }
    
    func flushTextureCache() {
        textureCache = nil
    }
    
    private func setupRenderPassDescriptor() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.renderPassDescriptor = renderPassDescriptor
    }
    
    private func makeTexture(width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = self.pixelFormat
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        return texture
    }

    private func setupTransform() {
        transform.delegate = self
        //For more memory managament, go to http://metalkit.org/2017/04/30/working-with-memory-in-metal.html
        quadVertexBuffer = device.makeBuffer(bytes: transform.quadVertices, length: transform.quadVertices.count * MemoryLayout<RTEVertex>.stride, options: [])
        quadVertexBuffer.label = "Quad_vertex_buffer"
        
        uniformBuffer = device.makeBuffer(length: MemoryLayout<RTEUniforms>.stride, options: .storageModeShared)
        uniformBuffer.label = "Uniform_buffer"
    }
    
    private func updateDrawState() {
        if let pixelBuffer = self.curPixelBuffer {
            transform.videoTextureSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                                                height: CVPixelBufferGetHeight(pixelBuffer))
        }
        let uniform = uniformBuffer.contents().bindMemory(to: RTEUniforms.self, capacity: 1)
        uniform[0].mvp = transform.mvp
    }
    
    private func makePixelBufferPool(_ pixelBuffer: CVPixelBuffer) -> CVPixelBufferPool? {
        let pool = allocateOutputBufferPool(pixelFormat: .pixelFormat_32BGRA,
                                            width: CVPixelBufferGetWidth(pixelBuffer),
                                            height: CVPixelBufferGetHeight(pixelBuffer),
                                            bufferCountHint: 3)

        return pool
    }
}

extension MetalVideoRenderer: VideoRenderer {
    func processPixelBuffer(_ buffer: CVPixelBuffer, at time: CMTime) {
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            if (self.outputPixelBufferPool == nil) {
                self.outputPixelBufferPool = self.makePixelBufferPool(buffer)
                self.filterContext = FilterSharedContext(device: self.device,
                                                   commandQueue: self.commandQueue,
                                                   textureCache: self.textureCache,
                                                   pixelBufferPool: outputPixelBufferPool,
                                                   drawableSize: self.transform.drawableSize)
                
            }
        }

        self.curPixelBuffer = filterManager.render(pixelBuffer: buffer, context: filterContext!)
    }
    
    func presentDrawable(_ drawable: Drawable?) {
        guard inFlightSemaphore.wait(timeout: DispatchTime.distantFuture) == .success else {
            print("Waiting semaphore")
            return
        }
        
        guard let pixelBuffer = self.curPixelBuffer else {
            print("Invalid pixelBuffer")
            return
        }
        
        guard let renderPassDescriptor = self.renderPassDescriptor else {
            assertionFailure("Invalid renderPassDescriptor")
            return
        }
        
        guard let drawable = drawable as? CAMetalDrawable else {
            assertionFailure("Invalid drawable content")
            return
        }
        
        guard let commandQueue = commandQueue else {
            assertionFailure("Failed to create Metal command queue")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            assertionFailure("Failed to create Metal command buffer")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            self.updateDrawState()
        }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            assertionFailure("Failed to create Metal command encoder")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        if self.textureCache == nil { setupTextureCache() }
        let texture = makeTextureFromCVPixelBuffer(pixelBuffer, textureFormat: self.pixelFormat, cache: textureCache)
        
        commandEncoder.pushDebugGroup("Draw video")
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(RTEBufferIndexUniforms.rawValue))
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(RTEBufferIndexUniforms.rawValue))
        commandEncoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: Int(RTEBufferIndexVertices.rawValue))
        
        let viewport = MTLViewport(originX: 0.0,
                                   originY: 0.0,
                                   width: Double(transform.drawableSize.width),
                                   height: Double(transform.drawableSize.height),
                                   znear: -1,
                                   zfar: 1)
        commandEncoder.setViewport(viewport)
        
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.popDebugGroup()
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        
        // Add completion hander which signals inFlightSemaphore when Metal and the GPU has fully
        // finished proccessing the commands encoded this frame. This indicates when the dynamic
        // buffers, written to this frame, will no longer be needed by Metal and the GPU, meaning the
        // buffer contents can be changed without corrupting rendering

        commandBuffer.addCompletedHandler { (_) in
            self.inFlightSemaphore.signal()
        }
        
        commandBuffer.commit()
    }
}

extension MetalVideoRenderer: VideoTransformDelegate {
    func rendererDidChangeDrawableSize(_ viewport: CGSize) {
        syncQueue.async {
            self.outputPixelBufferPool = nil
            self.outputFormatDescription = nil
            self.filterContext = nil
        }
    }
}
