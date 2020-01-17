//
//  FFReaderManager.h
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class FFAsset;
@class FFVideoFrame;
@interface FFReaderManager : NSObject
- (instancetype)initWithAsset:(FFAsset *)asset;

- (void)startReading:(NSError **)error;

- (FFVideoFrame *)nextVideoFrame;
@end

NS_ASSUME_NONNULL_END
