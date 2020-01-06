//
//  UIImage+extension.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import VideoToolbox

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
            return nil
        }
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        if let image = cgImage {
            self.init(cgImage: image)
        } else {
            return nil
        }
    }
}
