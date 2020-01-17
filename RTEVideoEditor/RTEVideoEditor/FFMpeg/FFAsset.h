//
//  FFAsset.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//#import "avformat.h"

NS_ASSUME_NONNULL_BEGIN

@interface FFAsset : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign, readonly) CGFloat fps;

- (instancetype)initWithURL:(NSURL *)url;

- (CGSize)frameSize;

- (CGFloat)sampleRate;

- (CGFloat)duration;

- (CGFloat)startTime;

- (CGFloat)fps;

- (BOOL)hasVideo;

- (BOOL)hasAudio;

@end

NS_ASSUME_NONNULL_END
