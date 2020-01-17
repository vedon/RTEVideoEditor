//
//  FFConvert.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/27.
//

#import <Foundation/Foundation.h>
#import <FFmpeg-Pod/libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface FFConvert : NSObject
+ (void)convertAVFrame:(AVFrame *)frame toPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
