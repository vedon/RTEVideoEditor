//
//  Samplers.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/9.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import MetalKit

enum RTESampler {
    case clampToEdge
    case `repeat`
    case mirrorRepeat
    case clampToZero
    
    func makeWith(device: MTLDevice) -> MTLSamplerState? {
        return device.makeSamplerState(descriptor: self.sampleDescriptor)
    }
    
    var sampleDescriptor: MTLSamplerDescriptor {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        
        switch self {
        case .clampToEdge:
            samplerDescriptor.sAddressMode = .clampToEdge
            samplerDescriptor.tAddressMode = .clampToEdge
        case .clampToZero:
            samplerDescriptor.sAddressMode = .clampToZero
            samplerDescriptor.tAddressMode = .clampToZero
        case .repeat:
            samplerDescriptor.sAddressMode = .repeat
            samplerDescriptor.tAddressMode = .repeat
        case .mirrorRepeat:
            samplerDescriptor.sAddressMode = .mirrorRepeat
            samplerDescriptor.tAddressMode = .mirrorRepeat
        }
        return samplerDescriptor
    }
}
