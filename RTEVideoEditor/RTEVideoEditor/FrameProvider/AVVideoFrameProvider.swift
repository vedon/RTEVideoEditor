//
//  AVVideoFrameProvider.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation
import AVFoundation

class AVVideoFrameProvider: NSObject {
    private let outputItemProcessQueue: DispatchQueue
    private var playItem: AVPlayerItem?
    private var player: AVPlayer?
    private var didPlayToEnd: Bool = false
    private var latestPixelBuffer: CVPixelBuffer?
    private var forceRender: Bool = false
    var duration: Double = 0.0
    
    var isPaused: Bool = true {
        didSet {
            assert(self.player != nil)
            isPaused ? self.player?.pause() : self.player?.play()
        }
    }
    
    var asset: AVAsset? = nil {
        didSet {
            guard let asset = self.asset else { return }
            if let playItem = self.playItem {
                playItem.remove(self.outputItem)
            }
            
            let playItem = AVPlayerItem(asset: asset)
            self.player = AVPlayer.init(playerItem: playItem)
            self.playItem = playItem
            self.playItem?.add(self.outputItem)

            NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlay(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playItem)
        }
    }
    
    private lazy var outputItem: AVPlayerItemVideoOutput = {
       let attributes = [String(kCVPixelBufferPixelFormatTypeKey):
        NSNumber(value: kCVPixelFormatType_32BGRA)]
       let outputItem = AVPlayerItemVideoOutput.init(pixelBufferAttributes: attributes)
        
        outputItem.requestNotificationOfMediaDataChange(withAdvanceInterval: 1/10)
        outputItem.setDelegate(self, queue: outputItemProcessQueue)
        return outputItem
    }()
    
    override init() {
        self.outputItemProcessQueue = DispatchQueue.init(label: "VideoFrameExtractor.OutputItem")
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didFinishPlay(_ notification: NSNotification) {
        outputItemProcessQueue.sync {
            self.didPlayToEnd = true
        }
    }
}

extension AVVideoFrameProvider: VideoFrameProvider {
    func pixelBuffer(at timeInterval: Double, completion: (Result<ExtractorContext, ExtractStatus>) -> Void) {
        guard didPlayToEnd == false else {
            completion(.failure(.finish))
            return
        }
        
        let time = outputItem.itemTime(forHostTime: timeInterval)
        self.duration = CMTimeGetSeconds(time)
        
        if self.forceRender, let newPixelBuffer = self.latestPixelBuffer {
            self.forceRender = false
            completion(.success(ExtractorContext(pixelBuffer: newPixelBuffer, time: time)))
        }
        
        guard outputItem.hasNewPixelBuffer(forItemTime: time) else {
            completion(.failure(.empty))
            return
        }
        
        guard let newPixelBuffer = outputItem.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            completion(.failure(.empty))
            return
        }
        self.latestPixelBuffer = newPixelBuffer
        completion(.success(ExtractorContext(pixelBuffer: newPixelBuffer, time: time)))
    }
    
    func seekToTime(_ time: CMTime) {
        Logger.shared.image("Seek to time \(CMTimeGetSeconds(time))")
        outputItemProcessQueue.sync {
            self.didPlayToEnd = false
        }
        
        player?.pause()
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let toleranceBefore = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        let toleranceAfter = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        
        self.player?.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: { (isFinish) in
            self.perform(#selector(self.deferToPlay), with: nil, afterDelay: 0.1)
        })
    }
    
    func replay() {
        self.forceRender = true
    }
    
    @objc private func deferToPlay() {
        if !self.isPaused {
            self.player?.play()
        }
    }
}

extension AVVideoFrameProvider: AVPlayerItemOutputPullDelegate {
}
