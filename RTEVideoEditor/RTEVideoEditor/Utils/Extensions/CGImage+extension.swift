//
//  CGImage+extension.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/10.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import Metal
import UIKit

extension CGImage {
    func grayPixels() -> [Int16] {
        var pixels = [Int16](repeatElement(0, count: width * height))
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 16, bytesPerRow: 2 * width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
    
    func rgbPixels() -> [UInt32] {
        var pixels = [UInt32](repeatElement(0, count: width * height))
        // Apple's bug(Only Swift): wrong bytesPerRow. Use workaround.
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}
