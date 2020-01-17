//
//  FFReaderManager.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFReaderManager.h"
#import <FFmpeg-Pod/libavformat/avformat.h>
#import "FFAsset.h"
#import "FFAsset_Private.h"
#import "FFDecoder.h"
#import "FFVideoFrame.h"

@interface FFReaderManager()
@property (nonatomic, strong) FFDecoder *decoder;
@end

@implementation FFReaderManager

- (instancetype)initWithAsset:(FFAsset *)asset {
    if (self = [super init]) {
        self.decoder = [[FFDecoder alloc] initWithAsset:asset];
    }
    return self;
}

- (void)startReading:(NSError **)error {
    [self.decoder decodeFramesInDuration:1.0];
    
    
//    [self.decoder videoFrameAtTime:12.0];
//    [self.decoder seekToTime:12];
//    self.decoder.currentFrame;
}

- (FFVideoFrame *)nextVideoFrame {
    return [self.decoder nextVideoFrame];
}

@end
