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
    
    private let metalEngine: RendererEngine?
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
        let metalEngine = MetalEngine.init()
        let metalView = MetalView.init(frame: .zero)
        metalView.drawableSizeDidChange = { size in
            metalEngine?.transform.drawableSize = size
        }
        
        self.layer = metalView
        self.metalEngine = metalEngine
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
    
    func add(filter: RTEFilterType) {
        metalEngine?.filterGroup.add(filter: filter)
        setNeedDisplay()
    }
    
    func remove(filter: RTEFilterType) {
        metalEngine?.filterGroup.remove(filter: filter)
        setNeedDisplay()
    }
    
    func update(filter: RTEFilterType, params: FilterParams) {
        metalEngine?.filterGroup.update(filter: filter, params: params)
        setNeedDisplay()
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
                self.metalEngine?.processPixelBuffer(context.pixelBuffer, at: context.time)
                self.metalEngine?.presentDrawable(self.layer.nextDrawable())
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
