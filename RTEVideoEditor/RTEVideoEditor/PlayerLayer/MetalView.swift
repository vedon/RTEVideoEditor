//
//  MetalView.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import AVFoundation

class MetalView: UIView {
    let pixelFormat: MTLPixelFormat = .bgra8Unorm
    
    var drawableSizeDidChange: ((_ size: CGSize) -> Void)?
    private var metalLayer: CAMetalLayer?
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .red
        setupMetalLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = CGSize.init(width: self.frame.size.width * UIScreen.main.scale,
        height: self.frame.size.height * UIScreen.main.scale)
        self.metalLayer?.drawableSize = size
        
        drawableSizeDidChange?(size)
    }
    
    private func setupMetalLayer() {
        self.metalLayer = self.layer as? CAMetalLayer
        metalLayer?.pixelFormat = self.pixelFormat
        metalLayer?.contentsScale = UIScreen.main.scale
    }
}

extension MetalView: VideoPlayerLayer {    
    func nextDrawable() -> Drawable? {
        return metalLayer?.nextDrawable()
    }
}
