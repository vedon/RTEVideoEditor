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
    case finish
}

struct ExtractorContext {
    let pixelBuffer: CVPixelBuffer
    let time: CMTime
}

typealias ExtractCompletion = (_ result: Result<ExtractorContext, ExtractStatus>) -> Void

protocol VideoFrameProvider {
    var asset: AVAsset? { get set }
    var isPaused: Bool { get set }
    var duration: Double { get }
    
    func seekToTime(_ time: CMTime)
    func replay()
    func pixelBuffer(at timeInterval: Double, completion: ExtractCompletion)
}

