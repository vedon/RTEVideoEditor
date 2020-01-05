//
//  MediaFrameExtractor.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2019/12/30.
//  Copyright © 2019 Free. All rights reserved.
//

import Foundation
import AVFoundation

enum ExtractStatus: Error {
    case empty
}

struct ExtractorContext {
    let pixelBuffer: CVPixelBuffer
    let time: CMTime
}

typealias ExtractCompletion = (_ result: Result<ExtractorContext, ExtractStatus>) -> Void

protocol VideoFrameExtractor {
    var asset: AVAsset? { get set }
    var isPaused: Bool { get set }
    func seekToTime(_ time: CMTime)
    func pixelBuffer(at timeInterval: Double, completion: ExtractCompletion)
}

class AVVideoFrameExtractor: NSObject {
    private let outputItemProcessQueue: DispatchQueue
    private var playItem: AVPlayerItem?
    private var player: AVPlayer?
    
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
}

extension AVVideoFrameExtractor: VideoFrameExtractor {
    func pixelBuffer(at timeInterval: Double, completion: (Result<ExtractorContext, ExtractStatus>) -> Void) {
        
        let time = self.outputItem.itemTime(forHostTime: timeInterval)
        guard outputItem.hasNewPixelBuffer(forItemTime: time) else {
            completion(.failure(.empty))
            return
        }
        
        guard let buffer = outputItem.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            completion(.failure(.empty))
            return
        }
        
        completion(.success(ExtractorContext(pixelBuffer: buffer, time: time)))
    }
    
    func seekToTime(_ time: CMTime) {
        Logger.shared.image("Seek to time \(CMTimeGetSeconds(time))")
        
        self.player?.pause()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        let toleranceBefore = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        let toleranceAfter = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        
        self.player?.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: { (isFinish) in
            self.perform(#selector(self.deferToPlay), with: nil, afterDelay: 0.1)
        })
    }
    
    @objc private func deferToPlay() {
        self.player?.play()
    }
}

extension AVVideoFrameExtractor: AVPlayerItemOutputPullDelegate {
}
