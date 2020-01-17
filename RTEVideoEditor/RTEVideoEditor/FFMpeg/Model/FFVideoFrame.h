//
//  FFVideoFrame.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import "FFFrame.h"
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef enum {
    FFVideoFrameFormatRGB,
    FFVideoFrameFormatYUV,
    
} FFVideoFrameFormat;

@interface FFVideoFrame : FFFrame
@property (nonatomic, assign) FFVideoFrameFormat format;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

- (CMSampleBufferRef)sampleBuffer;
@end

@interface FFVideoFrameRGB : FFVideoFrame
@property (nonatomic, assign) NSUInteger linesize;
@property (nonatomic, strong) NSData *rgb;
- (UIImage *) asImage;
@end

@interface FFVideoFrameYUV : FFVideoFrame
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@end

NS_ASSUME_NONNULL_END
