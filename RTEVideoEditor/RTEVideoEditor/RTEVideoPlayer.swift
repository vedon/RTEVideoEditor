//
//  VideoPlayer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2019/12/30.
//  Copyright © 2019 Free. All rights reserved.
//

import UIKit
import AVFoundation

protocol RTEVideoPlayerDelegate: class {
    func playerSliderDidChange(_ player: RTEVideoPlayer)
    func playerDidPlayToEnd(_ player: RTEVideoPlayer)
}

class RTEVideoPlayer {
    let layer: VideoPlayerLayer
    
    private let renderer: VideoRenderer?
    private var displayLink: CADisplayLink?
    private var frameProvider: VideoFrameProvider
    weak var delegate: RTEVideoPlayerDelegate?
    
    var asset: AVAsset? { didSet { frameProvider.asset = asset } }
    
    var duration: CMTime {
        guard let asset = frameProvider.asset else { return CMTime.zero }
        return asset.duration
    }
    
    var progress: Float {
        return Float(frameProvider.duration / CMTimeGetSeconds(duration))
    }
    
    init() {
        let metalRenderer = MetalVideoRenderer.init()
        let metalView = MetalView.init(frame: .zero)
        metalView.drawableSizeDidChange = { size in
            metalRenderer?.transform.drawableSize = size
        }
        
        self.layer = metalView
        self.renderer = metalRenderer
        self.frameProvider = AVVideoFrameProvider.init()
        
        setupDisplayLink()
    }
    
    @discardableResult func start() -> Bool {
        guard self.asset != nil else { return false }
        displayLink?.isPaused = false
        frameProvider.isPaused = false
        return true
    }
    
    func stop() {
        displayLink?.isPaused = true
        frameProvider.isPaused = true
    }
    
    func seekToTime(_ time: CMTime, autoPlay: Bool = true) {
        frameProvider.seekToTime(time)
        frameProvider.isPaused = !autoPlay
    }
    
    func setNeedDisplay() {
        frameProvider.replay()
    }
    
    func add(filter: RTEFilter) {
        self.renderer?.filterManager.add(filter: filter)
        self.setNeedDisplay()
    }
    
    func remove(filter: RTEFilter) {
        self.renderer?.filterManager.remove(filter: filter)
        self.setNeedDisplay()
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
        frameProvider.pixelBuffer(at: timeInterval) { [weak self] (result) in
            guard let `self` = self else { return }
            switch result {
            case .success(let context):
                self.renderer?.processPixelBuffer(context.pixelBuffer, at: context.time)
                self.renderer?.presentDrawable(self.layer.nextDrawable())
                DispatchQueue.main.async {
                    self.delegate?.playerSliderDidChange(self)
                }
            case .failure(let status):
                switch status {
                case .finish: self.delegate?.playerDidPlayToEnd(self)
                default: break
                }
            }
        }
    }
}
