//
//  FFFrame.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
#import <CoreMedia/CMTimeRange.h>
#import <AVFoundation/AVFoundation.h>
typedef enum {
    FFFrameTypeVideo,
    FFFrameTypeAudio,
    FFFrameTypeSubtitle,
} FFFrameType;

NS_ASSUME_NONNULL_BEGIN

@interface FFFrame : NSObject
@property (nonatomic, assign) FFFrameType type;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CMTime position;
@end

NS_ASSUME_NONNULL_END
