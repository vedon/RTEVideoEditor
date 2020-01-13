//
//  OpenGLVideoRenderer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/7.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation

class OpenGLVideoRenderer {
    let filterManager: FilterManager
    
    init() {
        self.filterManager = FilterManager()
    }
}

extension OpenGLVideoRenderer: VideoRenderer {
    func processPixelBuffer(_ buffer: CVPixelBuffer, at time: CMTime) {
        
    }
    
    func presentDrawable(_ drawable: Drawable?) {
        
    }

}
