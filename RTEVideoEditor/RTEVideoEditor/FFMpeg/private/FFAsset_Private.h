//
//  FFAsset_Private.h
//  Pods
//
//  Created by weidong fu on 2019/8/26.
//

#ifndef FFAsset_Private_h
#define FFAsset_Private_h
#import <FFmpeg-Pod/libavformat/avformat.h>

@interface FFAsset()
@property (nonatomic, assign) AVFormatContext *formatContext;
@property (nonatomic, assign) AVCodec *videoCodec;
@property (nonatomic, assign) AVCodecParameters *videoCodecParam;
@property (nonatomic, assign) AVCodecContext *videoCodecCtx;
@property (nonatomic, assign) int videoStreamIndex;
@property (nonatomic, assign) CGFloat videoTimeBase;
@property (nonatomic, assign) CGFloat videoFps;
@property (nonatomic, assign) AVStream *videoStream;

@property (nonatomic, assign) AVCodec *audioCodec;
@property (nonatomic, assign) AVCodecParameters *audioCodecParam;
@property (nonatomic, assign) AVCodecContext *audioCodecCtx;
@property (nonatomic, assign) int audioStreamIndex;
@property (nonatomic, assign) CGFloat audioTimeBase;
@property (nonatomic, assign) AVStream *audioStream;

@property (nonatomic, assign) int subtitleStreamIndex;


- (void)setupCodecs:(NSError **)error;
@end

#endif /* FFAsset_Private_h */
