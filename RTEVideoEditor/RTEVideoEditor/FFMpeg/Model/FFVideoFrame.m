//
//  FFVideoFrame.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFVideoFrame.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation FFVideoFrame
- (FFFrameType)type {
    return FFFrameTypeVideo;
}

- (void)dealloc {
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = nil;
    }
}

- (CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, _pixelBuffer, &outputFormatDescription );
    CMSampleBufferRef sampleBuffer = NULL;
    
    CMSampleTimingInfo timingInfo = {CMTimeMake(1, 30), kCMTimeZero, kCMTimeInvalid};
    OSStatus status = CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, _pixelBuffer, outputFormatDescription, &timingInfo, &sampleBuffer);
    if (outputFormatDescription) {
        CFRelease(outputFormatDescription);
    }
    outputFormatDescription = NULL;
    return sampleBuffer;
}
@end

@implementation FFVideoFrameRGB
- (FFVideoFrameFormat)format {
    return FFVideoFrameFormatRGB;
}

- (UIImage *)asImage {
    UIImage *image = nil;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}

@end

@implementation FFVideoFrameYUV
- (FFVideoFrameFormat)format {
    return FFVideoFrameFormatYUV;
}
@end
