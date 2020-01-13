//
//  RendererTransform.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2019 Free. All rights reserved.
//

import AVFoundation
import UIKit
import MetalKit
import MetalPerformanceShaders

protocol VideoTransformDelegate: class {
    func rendererDidChangeDrawableSize(_ viewport: CGSize)
}

class RendererTransform {
    weak var delegate: VideoTransformDelegate?
    private var projectionMatrix: matrix_float4x4
    private var scaleMatrix: matrix_float4x4
    
    private var mvpMatrix: matrix_float4x4?
    
    let quadVertices: [RTEVertex]
    var mvp: matrix_float4x4 {
        if let matrix = mvpMatrix {
            return matrix
        } else {
            mvpMatrix = calMvpMatrix()
            return mvpMatrix!
        }
    }
    var rotateDegree: Float
    var scale: packed_float2
    
    var drawableSize: CGSize {
        didSet {
            if !oldValue.equalTo(drawableSize) {
                Logger.shared.transfrom("drawableSize: \(drawableSize)")
                projectionMatrix = matrix_perspective_left_hand(radians_from_degrees(60), Float(drawableSize.ratio()), 0.001, 10.0);
                mvpMatrix = nil
                delegate?.rendererDidChangeDrawableSize(drawableSize)
            }
        }
    }
    
    var videoTextureSize: CGSize {
        didSet {
            if !oldValue.equalTo(videoTextureSize) {
                Logger.shared.transfrom("videoTextureSize: \(videoTextureSize)")
                mvpMatrix = nil
            }
        }
    }

    init() {
        self.mvpMatrix = matrix4x4_identity()
        self.projectionMatrix = matrix4x4_identity()
        self.scaleMatrix = matrix4x4_scale(1.0, 1.0, 1.0)
        self.drawableSize = .zero
        self.videoTextureSize = .zero
        
        self.rotateDegree = 0.0
        self.scale = packed_float2(1.0, 1.0)
        
        /* Vertex
         (-1,1)  (1, 1)
            .-----.
            |\    |
            | \   |
            |  \  |
            |   \ |
            |    \|
            .-----.
         (-1,-1) (1, -1)
        */

        /* Texture
         (0,0)  (1, 0)
            .-----.
            |\    |
            | \   |
            |  \  |
            |   \ |
            |    \|
            .-----.
         (0,1) (1, 1)
         */
        let x: Float = 1.0
        let y: Float = 1.0
        self.quadVertices = [
            RTEVertex(position: vector_float4(x, y, 0.0, 1.0), texCoord: packed_float2(1.0, 0.0)),
            RTEVertex(position: vector_float4(-x, y, 0.0, 1.0), texCoord: packed_float2(0.0, 0.0)),
            RTEVertex(position: vector_float4(x, -y, 0.0, 1.0), texCoord: packed_float2(1.0, 1.0)),
            RTEVertex(position: vector_float4(-x, -y, 0.0, 1.0), texCoord: packed_float2(0.0, 1.0)),
        ]
    }
    
    private func makeScaleMatrix() -> matrix_float4x4 {
        guard videoTextureSize.isValid() else {
            return matrix4x4_scale(1.0, 1.0, 1.0)
        }
        
        guard drawableSize.isValid() else {
            Logger.shared.warn("Invalid texture size")
            return matrix4x4_scale(1.0, 1.0, 1.0)
        }
        
        var aspectFitScale = self.scale
        var scale: Float = 1.0
        
        if videoTextureSize.ratio() > drawableSize.ratio() {
            aspectFitScale.y = 1.0 / Float(videoTextureSize.ratio())
            scale = Float(drawableSize.ratio())
        } else {
            aspectFitScale.x = Float(videoTextureSize.ratio())
        }
        return matrix4x4_scale(aspectFitScale.x * scale, aspectFitScale.y * scale, 1.0)
    }
    
    private func calMvpMatrix() -> matrix_float4x4 {
        scaleMatrix = makeScaleMatrix()
        
        let rotation: matrix_float4x4 = matrix4x4_rotation(radians_from_degrees(self.rotateDegree), 0.0, 0.0, 1.0);
        let translation: matrix_float4x4 = matrix4x4_translation(0.0, 0.0, 0.0)
        
        let st = matrix_multiply(translation, self.scaleMatrix)
        let str: matrix_float4x4 = matrix_multiply(rotation, st)
        let modelMatrix = str
                
//        let modelMatrix = { () -> matrix_float4x4 in
//            let rotation: matrix_float4x4 = matrix4x4_rotation(radians_from_degrees(self.rotateDegree), 0.0, 0.0, 1.0);
//            let translation: matrix_float4x4 = matrix4x4_translation(0.0, 0.0, 0.0)
//            let tr = matrix_multiply(rotation, translation)
//            let trs: matrix_float4x4 = matrix_multiply(self.scaleMatrix, tr)
//            return trs
//        }

        //The coordinate system of view matrix must be the same as project matrix
        let distance = Float(1.0 / tan(radians_from_degrees(30)))
        let viewMatrix = matrix_look_at_left_hand(0.0, 0.0, -distance, // camera position
                                                  0.0, 0.0, 0.0,  // world center
                                                  0.0, 1.0, 0.0)  // camera orientation
        return matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix))
    }
}
