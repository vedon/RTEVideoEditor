//
//  FFDecoder.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import "FFAsset.h"

@class FFFrame;
@class FFVideoFrame;
NS_ASSUME_NONNULL_BEGIN

@interface FFDecoder : NSObject
@property (nonatomic, strong, readonly) FFVideoFrame *nextVideoFrame;
- (instancetype)initWithAsset:(FFAsset *)asset;

- (void)seekToTime:(CGFloat)seconds;

- (FFVideoFrame *)videoFrameAtTime:(CGFloat)second;

- (NSArray <FFFrame *> *)decodeFramesInDuration:(CGFloat)duration;
@end

NS_ASSUME_NONNULL_END
