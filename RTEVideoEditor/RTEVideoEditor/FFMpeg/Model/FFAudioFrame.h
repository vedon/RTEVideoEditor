//
//  FFAudioFrame.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import "FFFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface FFAudioFrame : FFFrame
@property (nonatomic, strong) NSData *samples;
@end

NS_ASSUME_NONNULL_END
