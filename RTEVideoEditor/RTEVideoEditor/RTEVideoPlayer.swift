//
//  VideoPlayer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2019/12/30.
//  Copyright © 2019 Free. All rights reserved.
//

import UIKit
import AVFoundation

class RTEVideoPlayer {
    let layer: VideoPlayerLayer
    
    private var displayLink: CADisplayLink?
    private let renderer: VideoRenderer?
    private var frameExtractor: VideoFrameExtractor
    
    var asset: AVAsset? {
        didSet {
            frameExtractor.asset = asset
        }
    }
    
    init() {
        let metalRenderer = MetalVideoRenderer.init()
        let metalView = MetalView.init(frame: .zero)
        metalView.drawableSizeDidChange = { size in
            metalRenderer?.transform.drawableSize = size
        }
        
        self.layer = metalView
        self.renderer = metalRenderer
        self.frameExtractor = AVVideoFrameExtractor.init()
        
        //Filters
        self.renderer?.addFilter(RosyFilterRenderer())
        
        setupDisplayLink()
    }
    
    @discardableResult func start() -> Bool {
        guard self.asset != nil else { return false }
        displayLink?.isPaused = false
        frameExtractor.isPaused = false
        return true
    }
    
    func stop() {
        displayLink?.isPaused = true
        frameExtractor.isPaused = true
    }
    
    func seekToTime(_ time: CMTime) {
        frameExtractor.seekToTime(time)
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setupDisplayLink() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(redraw(sender:)))
        displayLink?.add(to: RunLoop.main, forMode: .common)
    }
    
    @objc func redraw(sender: CADisplayLink) {
        let timeInterval = sender.timestamp + sender.duration
        frameExtractor.pixelBuffer(at: timeInterval) { [weak self] (result) in
            guard let context = try? result.get() else { return }
            
            self?.renderer?.processPixelBuffer(context.pixelBuffer, at: context.time)
            
            self?.renderer?.presentDrawable(self?.layer.nextDrawable())
        }
    }
}
