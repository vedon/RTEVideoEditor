//
//  FFDecodeContext.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFDecodeContext.h"
#import "FFAsset_Private.h"
#import <libavutil/imgutils.h>

@interface FFDecodeContext()
@property (nonatomic, strong) FFAsset *asset;
@property (nonatomic, assign) struct SwsContext *swsContext;
@property (nonatomic, assign) SwrContext *swrContext;
@property (nonatomic, assign) AVFrame *videoFrame;
@property (nonatomic, assign) AVFrame *audioFrame;
@property (nonatomic, assign) AVPacket *packet;
@property (nonatomic, assign) FFVideoFrameFormat vFrameFormat;

@property (nonatomic, assign) AVFrame *rgbVideoFrame;
@property (nonatomic, assign) uint8_t *rgbBuffer;
@end

@implementation FFDecodeContext

- (instancetype)initWithAsset:(FFAsset *)asset {
    if (self = [super init]) {
        self.asset = asset;
    }
    return self;
}

- (void)dealloc {
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_swrContext) {
        swr_free(&(_swrContext));
        _swrContext = NULL;
    }

    if (_rgbVideoFrame) {
        av_frame_free(&_rgbVideoFrame);
        _rgbVideoFrame = NULL;
    }
    
    if (_rgbBuffer) {
        av_free(_rgbBuffer);
        _rgbBuffer = NULL;
    }
    
    if(_videoFrame) {
        av_frame_free(&_videoFrame);
        _videoFrame = NULL;
    }
    
    if (_audioFrame) {
        av_frame_free(&_audioFrame);
        _audioFrame = NULL;
    }
    
    if (_packet) {
        av_packet_free(&_packet);
        _packet = NULL;
    }
}

- (struct SwsContext *)swsContext {
    if(_swsContext == NULL) {
        _swsContext = sws_getCachedContext(_swsContext,
                                           _asset.videoCodecCtx->width,
                                           _asset.videoCodecCtx->height,
                                           _asset.videoCodecCtx->pix_fmt,
                                           _asset.videoCodecCtx->width,
                                           _asset.videoCodecCtx->height,
                                           AV_PIX_FMT_RGBA,
                                           SWS_FAST_BILINEAR,
                                           NULL, NULL, NULL);
    }
    return _swsContext;
}

- (SwrContext *)swrContext {
    if(_swrContext == NULL) {
        //https://cloud.tencent.com/developer/article/1055338
        _swrContext = swr_alloc_set_opts(NULL,
                                        _asset.audioCodecCtx->channels,
                                        AV_SAMPLE_FMT_S16,
                                        _asset.audioCodecCtx->sample_rate,
                                        _asset.audioCodecCtx->channels,
                                        _asset.videoCodecCtx->sample_fmt,
                                        _asset.videoCodecCtx->sample_rate,
                                        0,
                                        NULL);
    }
    return _swrContext;
}

- (AVFrame *)videoFrame {
    if(_videoFrame == NULL) {
        _videoFrame = av_frame_alloc();
    }
    return _videoFrame;
}

- (AVFrame *)rgbVideoFrame {
    if(_rgbVideoFrame == NULL) {
        _rgbVideoFrame = av_frame_alloc();
        if (_rgbVideoFrame == NULL) {
            return nil;
        }
        
        int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, _asset.videoCodecCtx->width, _asset.videoCodecCtx->height, 1);
        self.rgbBuffer = (uint8_t *) av_malloc(numBytes * sizeof(uint8_t));

        av_image_fill_arrays(_rgbVideoFrame->data, _rgbVideoFrame->linesize, _rgbBuffer, AV_PIX_FMT_RGB24, _asset.videoCodecCtx->width, _asset.videoCodecCtx->height, 1);
    }
    return _rgbVideoFrame;
}

- (AVFrame *)audioFrame {
    if(_audioFrame == NULL) {
        _audioFrame = av_frame_alloc();
    }
    return _audioFrame;
}

- (AVPacket *)packet {
    if (_packet == NULL) {
        _packet = av_packet_alloc();
    }
    return _packet;
}

@end
