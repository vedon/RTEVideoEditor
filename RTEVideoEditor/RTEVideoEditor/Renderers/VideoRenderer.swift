//
//  VideoRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2019/12/30.
//  Copyright © 2019 Free. All rights reserved.
//

import Foundation
import AVFoundation

protocol VideoRenderer {
    func processPixelBuffer(_ buffer: CVPixelBuffer, at time: CMTime)
    func presentDrawable(_ drawable: Drawable?)
    func addFilter(_ filter: FilterRenderer)
}
