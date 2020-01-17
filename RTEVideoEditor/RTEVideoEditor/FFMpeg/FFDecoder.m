//
//  FFDecoder.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFDecoder.h"
#import "FFAsset_Private.h"
#import "FFFrame.h"
#import "FFVideoFrame.h"
#import "FFAudioFrame.h"
#import "FFDecodeContext.h"
#import <Accelerate/Accelerate.h>
#import <FFmpeg-Pod/libavformat/avformat.h>
#import "FFConvert.h"

@interface FFDecoder()
@property (nonatomic, strong) FFAsset *asset;
@property (nonatomic, assign) BOOL isEOF;
@property (nonatomic, assign) BOOL disableDeinterlacing;
@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) FFVideoFrameFormat videoFrameFormat;
@property (nonatomic, strong) FFDecodeContext *decodeCtx;
@property (nonatomic, assign) CGFloat decodeDuration;
@property (nonatomic, assign) CVPixelBufferPoolRef pixelBufferPool;
@end

@implementation FFDecoder
- (instancetype)initWithAsset:(FFAsset *)asset {
    if (self = [super init]) {
        self.asset = asset;
        self.decodeCtx = [[FFDecodeContext alloc] initWithAsset:asset];
        [self setup];
    }
    return self;
}

- (void)dealloc {
    self.decodeCtx = nil;
    
    if(self.pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
    }
}

- (FFVideoFrame *)videoFrameAtTime:(CGFloat)second {
    if (!self.asset.hasVideo) return nil;
    
    int64_t timestamp = [self calculateSeekTime:second];
    
    //https://stackoverflow.com/questions/39983025/how-to-read-any-frame-while-having-frame-number-using-ffmpeg-av-seek-frame/39990439
    if (av_seek_frame(_asset.formatContext, _asset.videoStreamIndex, timestamp, AVSEEK_FLAG_BACKWARD) < 0) {
        NSLog(@"Get video frame at time fail");
        return nil;
    }
    avcodec_flush_buffers(_asset.videoCodecCtx);
    return [self nextVideoFrame];
}

- (int64_t)calculateSeekTime:(CGFloat)second {
    //Equal to: second / self.asset.videoTimeBase
    int64_t timestamp = av_rescale_q(second * AV_TIME_BASE, AV_TIME_BASE_Q, self.asset.videoStream->time_base);
    if (timestamp < 0) {
        timestamp = _asset.videoStream->start_time;
    } else {
        timestamp += _asset.videoStream->start_time / _asset.videoTimeBase;
    }
    
    if(_asset.videoStream->duration) {
        timestamp = MIN(timestamp, _asset.videoStream->duration);
    }
    return timestamp;
}

- (FFVideoFrame *)nextVideoFrame {
    AVPacket *packet = self.decodeCtx.packet;
    FFVideoFrame *frame = nil;
    while (frame == nil) {
        if (av_read_frame(_asset.formatContext, packet) < 0) {
            NSLog(@"Get current frame fail, continue to read");
            av_packet_unref(packet);
            break;
        }
        NSLog(@"Send packet at time: %0.2f s",packet->pts * self.asset.videoTimeBase);
        int response = avcodec_send_packet(_asset.videoCodecCtx, packet);
        
        if (response < 0) {
            av_packet_unref(packet);
            NSLog(@"⚠️ error: %s", av_err2str(response));
            continue;
        }
        
        if (response >= 0) {
            response = avcodec_receive_frame(_asset.videoCodecCtx, self.decodeCtx.videoFrame);
            av_packet_unref(packet);
            
            if (self.decodeCtx.videoFrame->interlaced_frame) {
                NSLog(@"Processinng interlaced frame");
            }
        
            if (response == AVERROR(EAGAIN) || response == AVERROR_EOF) {
                continue;
            } else if (response < 0) {
                NSLog(@"Error while receiving a frame from the decoder: %s", av_err2str(response));
                continue;
            }
            frame = [self handleVideoFrame:self.decodeCtx.videoFrame];
        }
   
    }
    return frame;
}

- (void)seekToTime:(CGFloat)second {
    _position = second;
    _isEOF = NO;
    /*
     https://stackoverflow.com/questions/43333542/what-is-video-timescale-timebase-or-timestamp-in-ffmpeg
     For a fps=60/1 and timebase=1/60000 each PTS will increase timescale / fps = 1000 therefore the PTS real time for each frame could be (supposing it started at 0):
     
     frame=0, PTS = 0, PTS_TIME = 0
     frame=1, PTS = 1000, PTS_TIME = PTS * timebase = 0.016
     frame=2, PTS = 2000, PTS_TIME = PTS * timebase = 0.033
     
     Timebase = 1/75; Timescale = 75, FPS = 25
     pts = Timescale / FPS = 3
     
     Frame        pts           pts_time
     0          0          0 x 1/75 = 0.00
     1          3          3 x 1/75 = 0.04
     2          6          6 x 1/75 = 0.08
     3          9          9 x 1/75 = 0.12
     */
    
    if(self.asset.hasVideo) {
        int64_t timestamp = av_rescale_q(second * AV_TIME_BASE, AV_TIME_BASE_Q, self.asset.videoStream->time_base);
        avformat_seek_file(_asset.formatContext, _asset.videoStreamIndex, INT64_MIN, timestamp, INT64_MAX, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_asset.videoCodecCtx);
    }
    
    if(self.asset.hasAudio) {
        int64_t timestamp = av_rescale_q(second * AV_TIME_BASE, AV_TIME_BASE_Q, self.asset.audioStream->time_base);
        avformat_seek_file(_asset.formatContext, _asset.audioStreamIndex, INT64_MIN, timestamp, INT64_MAX, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_asset.audioCodecCtx);
    }
}

- (NSArray <FFFrame *> *)decodeFramesInDuration:(CGFloat)duration {
    if (!self.asset.hasVideo) { return nil; }
    self.decodeDuration = duration;

    NSMutableArray<FFFrame *> *frames = [NSMutableArray array];
    AVPacket *packet = self.decodeCtx.packet;
    CGFloat decodedDuration = 0;

    while (decodedDuration < self.decodeDuration) {
        if (av_read_frame(_asset.formatContext, packet) < 0) {
            _isEOF = YES;
            break;
        }
        
        if (packet->stream_index == _asset.videoStreamIndex) {
            [frames addObjectsFromArray:[self getVideoFramesFromPacket:packet
                                                            inDuration:&decodedDuration]];
        } else if (packet->stream_index == _asset.audioStreamIndex) {
            [frames addObjectsFromArray:[self getAudioFramesFromPacket:packet
                                                            inDuration:&decodedDuration]];
        } else if (packet->stream_index == _asset.subtitleStreamIndex) {
            //do nothing
        }
        av_packet_unref(packet);
    }
    return [frames copy];
}

- (NSArray <FFVideoFrame *> *)getVideoFramesFromPacket:(AVPacket *)packet inDuration:(CGFloat *)duration {
    NSMutableArray <FFVideoFrame *> * frames = [NSMutableArray array];
    
    int response = avcodec_send_packet(_asset.videoCodecCtx, packet);
    if (response < 0) {
        NSLog(@"Error while sending a packet to the decoder: %s", av_err2str(response));
        return frames;
    }
    
    while (response >= 0) {
        response = avcodec_receive_frame(_asset.videoCodecCtx, self.decodeCtx.videoFrame);
        if (response == AVERROR(EAGAIN) || response == AVERROR_EOF) {
            break;
        } else if (response < 0) {
            NSLog(@"Error while receiving a frame from the decoder: %s", av_err2str(response));
            break;
        }
        
        if (response >= 0) {
            FFVideoFrame *frame = [self handleVideoFrame:self.decodeCtx.videoFrame];
            if (frame) {
                [frames addObject:frame];
            
                _position = CMTimeGetSeconds(frame.position);
                
                *duration += frame.duration;
                if (*duration > self.decodeDuration) {
                    break;
                }
            }
        }
    }
    return frames;
}

- (NSArray <FFAudioFrame *> *)getAudioFramesFromPacket:(AVPacket *)packet inDuration:(CGFloat *)duration {
    
    NSMutableArray <FFAudioFrame *> * frames = [NSMutableArray array];
    CGFloat decodedDuration = 0;

    int response = avcodec_send_packet(_asset.audioCodecCtx, packet);
    if (response < 0) {
        NSLog(@"Error while sending a packet to the decoder: %s", av_err2str(response));
        return frames;
    }
    
    while (response >= 0) {
        response = avcodec_receive_frame(_asset.audioCodecCtx, self.decodeCtx.audioFrame);
        if (response == AVERROR(EAGAIN) || response == AVERROR_EOF) {
            break;
        } else if (response < 0) {
            NSLog(@"Error while receiving a frame from the decoder: %s", av_err2str(response));
            return frames;
        }
        
        if (response >= 0) {
            FFAudioFrame * frame = [self handleAudioFrame:self.decodeCtx.audioFrame];
            if (frame) {
                [frames addObject:frame];
                if (_asset.videoStreamIndex == -1) {
                    _position = CMTimeGetSeconds(frame.position);
                    *duration += frame.duration;
                    if (*duration > self.decodeDuration) {
                        break;
                    }
                }
            }
        }
    }
    return frames;
}

- (void)setup {
    switch (self.asset.videoCodecCtx->pix_fmt) {
        case AV_PIX_FMT_YUV420P:
        case AV_PIX_FMT_YUVJ420P:
            self.videoFrameFormat = FFVideoFrameFormatYUV;
            break;
        default:
            self.videoFrameFormat = FFVideoFrameFormatRGB;
            break;
    }
}

- (FFVideoFrame *)handleVideoFrame:(AVFrame *)videoFrame {
    [self setupPixelBufferPoolForFrame:videoFrame];
    
    FFVideoFrame *frame = nil;
    if (videoFrame->data[0] == NULL) {
        return frame;
    }
    AVCodecContext * videoCodecCtx = self.asset.videoCodecCtx;
    if (self.videoFrameFormat == FFVideoFrameFormatYUV) {
        FFVideoFrameYUV *yuvFrame = [[FFVideoFrameYUV alloc] init];
        yuvFrame.luma = copyFrameData(videoFrame->data[0],
                                      videoFrame->linesize[0],
                                      videoCodecCtx->width,
                                      videoCodecCtx->height);
        
        yuvFrame.chromaB = copyFrameData(videoFrame->data[1],
                                         videoFrame->linesize[1],
                                         videoCodecCtx->width / 2,
                                         videoCodecCtx->height / 2);
        
        yuvFrame.chromaR = copyFrameData(videoFrame->data[2],
                                         videoFrame->linesize[2],
                                         videoCodecCtx->width / 2,
                                         videoCodecCtx->height / 2);
        frame = yuvFrame;
    } else {
        //https://blog.csdn.net/leixiaohua1020/article/details/42134965
        if (self.decodeCtx.swsContext == NULL) {
            return  nil;
        }
        
        sws_scale(self.decodeCtx.swsContext,
                  (const uint8_t **)videoFrame->data,
                  videoFrame->linesize,
                  0,
                  videoCodecCtx->height,
                  self.decodeCtx.rgbVideoFrame->data,
                  self.decodeCtx.rgbVideoFrame->linesize);
        
        FFVideoFrameRGB *rgbFrame = [[FFVideoFrameRGB alloc] init];
        rgbFrame.linesize = self.decodeCtx.rgbVideoFrame->linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:self.decodeCtx.rgbVideoFrame->data[0]
                                      length:rgbFrame.linesize * videoCodecCtx->height];
        frame = rgbFrame;
    }
    
    frame.width = videoCodecCtx->width;
    frame.height = videoCodecCtx->height;
    //frame.position = av_frame_get_best_effort_timestamp(videoFrame) * _asset.videoTimeBase;
    frame.position = CMTimeMake(av_frame_get_best_effort_timestamp(videoFrame) , _asset.videoTimeBase);
    const int64_t frameDuration = av_frame_get_pkt_duration(self.decodeCtx.videoFrame);
    if (frameDuration) {
        
        frame.duration = frameDuration * _asset.videoTimeBase;
        frame.duration += self.decodeCtx.videoFrame->repeat_pict * _asset.videoTimeBase * 0.5;
        //if (_videoFrame->repeat_pict > 0) {
        //    LoggerVideo(0, @"_videoFrame.repeat_pict %d", _videoFrame->repeat_pict);
        //}
    } else {
        frame.duration = 1.0 / _asset.fps;
    }
    
    
    CVPixelBufferRef pixelBuffer = [self getEmptyPixelBuffer];
    [FFConvert convertAVFrame:videoFrame toPixelBuffer:pixelBuffer];
    frame.pixelBuffer = pixelBuffer;
    return frame;
}

- (FFAudioFrame *)handleAudioFrame:(AVFrame *)audioFrame {
    FFAudioFrame *frame = nil;
    if (audioFrame->data[0] == NULL) {
        return frame;
    }
    
    void * audioData;
    NSInteger numFrames;
    const numChannels = self.asset.videoCodecCtx->channels;
    if (self.decodeCtx.swrContext) {
        
    } else {
        
    }
    
    audioData = audioFrame->data[0];
    numFrames = audioFrame->nb_samples;
    
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioData, 1, data.mutableBytes, 1, numElements);
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
    
    frame = [[FFAudioFrame alloc] init];
    frame.position = CMTimeMake(av_frame_get_best_effort_timestamp(audioFrame) , _asset.audioTimeBase);
    frame.duration = av_frame_get_pkt_duration(audioFrame) * self.asset.audioTimeBase;
    frame.samples = data;
    
    if (frame.duration == 0) {
        // sometimes ffmpeg can't determine the duration of audio frame
        // especially of wma/wmv format
        // so in this case must compute duration
        frame.duration = frame.samples.length / (sizeof(float) * numChannels * self.asset.audioCodecCtx->sample_rate);
    }
    return frame;
}

- (CVPixelBufferRef)getEmptyPixelBuffer {
    CVReturn err;
    CVPixelBufferRef pixelBuffer = nil;
    err = CVPixelBufferPoolCreatePixelBuffer(NULL, self.pixelBufferPool, &pixelBuffer);
    NSAssert(err == kCVReturnSuccess, @"CVPixelBufferPoolCreatePixelBuffer fail");
    return pixelBuffer;
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

- (void)setupPixelBufferPoolForFrame:(AVFrame *)frame {
    if(_pixelBufferPool != nil) return;
    if(frame->data[0] == NULL) return;
    
    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    [attributes setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:kCVPixelBufferPixelFormatTypeKey];
    
    [attributes setObject:@(self.asset.videoCodecCtx->width) forKey: kCVPixelBufferWidthKey];
    [attributes setObject:@(self.asset.videoCodecCtx->height) forKey: kCVPixelBufferHeightKey];
    [attributes setObject:@(frame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
    
    [attributes setObject:@(1) forKey:kCVPixelBufferPoolMinimumBufferCountKey];
    [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    
    
    CVReturn error;
    error = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &_pixelBufferPool);
    NSAssert(error == kCVReturnSuccess, @"setupPixelBufferPoolForFrame fail");
}

@end

