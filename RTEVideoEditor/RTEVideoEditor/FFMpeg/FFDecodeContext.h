//
//  FFDecodeContext.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import <FFmpeg-Pod/libswscale/swscale.h>
#import <FFmpeg-Pod/libswresample/swresample.h>
#import <FFmpeg-Pod/libavutil/pixfmt.h>
#import <FFmpeg-Pod/libavformat/avformat.h>

#import "FFAsset.h"
#import "FFVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface FFDecodeContext : NSObject
@property (nonatomic, assign, readonly) struct SwsContext *swsContext;
@property (nonatomic, assign, readonly) SwrContext *swrContext;

@property (nonatomic, assign, readonly) AVFrame *videoFrame;
@property (nonatomic, assign, readonly) AVFrame *rgbVideoFrame;
@property (nonatomic, assign, readonly) AVFrame *audioFrame;
@property (nonatomic, assign, readonly) AVPacket *packet;
@property (nonatomic, assign, readonly) FFVideoFrameFormat vFrameFormat;
- (instancetype)initWithAsset:(FFAsset *)asset;

@end

NS_ASSUME_NONNULL_END
