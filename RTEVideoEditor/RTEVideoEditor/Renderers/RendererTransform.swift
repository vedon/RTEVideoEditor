//
//  RendererTransform.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2019 Free. All rights reserved.
//

import AVFoundation

protocol VideoTransformDelegate: class {
    func rendererDidChangeDrawableSize(_ viewport: CGSize)
}

class RendererTransform {
    weak var delegate: VideoTransformDelegate?
    private var projectionMatrix: matrix_float4x4
    private var scaleMatrix: matrix_float4x4
    
    let quadVertices: [RTEVertex]
    var rotateAngle: Float
    
    var drawableSize: CGSize {
        didSet {
            if !oldValue.equalTo(drawableSize) {
                Logger.shared.transfrom("drawableSize: \(drawableSize)")
                
                let aspect = drawableSize.width / drawableSize.height
                //How projective matrix define:
                //http://ogldev.atspace.co.uk/www/tutorial12/tutorial12.html
               
                //What the different between L and R hand
               //https://www.gamedev.net/articles/programming/graphics/perspective-projections-in-lh-and-rh-systems-r3598/
                projectionMatrix = matrix_perspective_left_hand(radians_from_degrees(60), Float(aspect), 0.001, 10.0);
               
                delegate?.rendererDidChangeDrawableSize(drawableSize)
            }
        }
    }
    
    var inputTextureSize: CGSize {
        didSet {
            if !oldValue.equalTo(inputTextureSize) {
                Logger.shared.transfrom("inputTextureSize: \(inputTextureSize)")
            }
        }
    }
    
    init() {
        self.projectionMatrix = matrix4x4_identity()
        self.scaleMatrix = matrix4x4_scale(1.0, 1.0, 1.0)
        self.drawableSize = .zero
        self.inputTextureSize = .zero
        self.rotateAngle = 0.0
        
        let x: Float = 1.0
        let y: Float = 1.0
        
        self.quadVertices = [
            RTEVertex(position: vector_float4(x, y, 0.0, 1.0), texCoord: packed_float2(1.0, 0.0)),
            RTEVertex(position: vector_float4(-x, y, 0.0, 1.0), texCoord: packed_float2(0.0, 0.0)),
            RTEVertex(position: vector_float4(x, -y, 0.0, 1.0), texCoord: packed_float2(1.0, 1.0)),
            RTEVertex(position: vector_float4(-x, -y, 0.0, 1.0), texCoord: packed_float2(0.0, 1.0)),
        ]
    }
    
    private func updateScaleMatrix() {
        guard inputTextureSize.isValid() else {
            Logger.shared.warn("Invalid render target size")
            return
        }
        
        guard drawableSize.isValid() else {
            Logger.shared.warn("Invalid texture size")
            return
        }

        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        
        if inputTextureSize.ratio() > 1.0 {
            scaleY *= Float(1.0 / inputTextureSize.ratio())
        } else if inputTextureSize.ratio() < 1.0 {
            scaleX *= Float(inputTextureSize.ratio())
        } else {
            
        }
        
        scaleMatrix = matrix4x4_scale(scaleX, scaleY, 1.0)
    }
    
    var mvp: matrix_float4x4 {
        updateScaleMatrix()
        
        let rotation: matrix_float4x4 = matrix4x4_rotation(radians_from_degrees(rotateAngle), 0.0, 0.0, 1.0);
        let translation: matrix_float4x4 = matrix4x4_translation(0.0, 0.0, 0.0)
        let rt = matrix_multiply(translation, rotation)
        let rts: matrix_float4x4 = matrix_multiply(scaleMatrix, rt) // The model matrix
        
        let distance = Float(1.0 / tan(radians_from_degrees(30)))
    
        //The coordinate system of view matrix must be the same as project matrix, aka, left hand
        let viewMatrix = matrix_look_at_left_hand(0.0, 0.0, -distance, // camera position
                                                  0.0, 0.0, 0.0,  // world center
                                                  0.0, 1.0, 0.0)  // camera orientation
        let modelMatrix = rts
        let mvp = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix));
        return mvp
    }
}

extension CGSize {
    func isValid() -> Bool {
        return self.width != 0 && self.height != 0
    }
    
    func ratio() -> CGFloat {
        return self.width / self.height
    }
}
