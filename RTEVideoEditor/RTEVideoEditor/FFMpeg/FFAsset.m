//
//  FFAsset.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFAsset.h"
#import <FFmpeg-Pod/libavformat/avformat.h>
#import "FFAsset_Private.h"
#define FFmpegOC_formatContext  @"FFmpegOC_formatContext"
#define FFmpegOC_openInput      @"FFmpegOC_openInput"
#define FFmpegOC_findStream     @"FFmpegOC_findStream"

#define FFmpegOC_noVideoCodec                        @"FFmpegOC_noVideoCodec"
#define FFmpegOC_videoCodecCtx                       @"FFmpegOC_videoCodecCtx"
#define FFmpegOC_videoCodecCtx_codecParams           @"FFmpegOC_videoCodecCtx_codecParams"
#define FFmpegOC_openVideoCodec                      @"FFmpegOC_openVideoCodec"

#define FFmpegOC_noAudioCodec                         @"FFmpegOC_noAudioCodec"
#define FFmpegOC_audioCodecCtx                        @"FFmpegOC_audioCodecCtx"
#define FFmpegOC_audioCodecCtx_codecParams            @"FFmpegOC_audioCodecCtx_codecParams"
#define FFmpegOC_openAudioCodec                       @"FFmpegOC_openAudioCodec"

@implementation FFAsset

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url;
        
        NSError *err = nil;
        self.audioStreamIndex = -1;
        self.videoStreamIndex = -1;
        self.subtitleStreamIndex = -1;
        
        [self setupAsset: &err];
        if (err != nil) {
            [self releaseAll];
        }
    }
    return self;
}

- (void)dealloc {
    [self releaseAll];
}

- (void)releaseAll {
    if(_formatContext != NULL) {
        avformat_close_input(&_formatContext);
        avformat_free_context(_formatContext);
    }
    
    [self releaseAudioStream];
    [self releaseVideoStream];
}

- (void)releaseVideoStream {
    self.videoStreamIndex = -1;
    
    if (_videoCodecCtx != NULL) {
        avcodec_free_context(&_videoCodecCtx);
        _videoCodecCtx = NULL;
    }
}

- (void)releaseAudioStream {
    self.audioStreamIndex = -1;
    
    if (_audioCodecCtx != NULL) {
        avcodec_free_context(&_audioCodecCtx);
        _audioCodecCtx = NULL;
    }
}

- (CGSize)frameSize {
    if (self.videoCodecCtx) {
        return CGSizeMake(self.videoCodecCtx ->width, self.videoCodecCtx ->height);
    } else {
        return CGSizeZero;
    }
}

- (CGFloat)sampleRate {
    return self.audioCodecCtx? self.audioCodecCtx->sample_rate : 0;
}

- (CGFloat)duration {
    if (self.formatContext) {
        if (_formatContext->duration == AV_NOPTS_VALUE)
            return MAXFLOAT;
        return (CGFloat)_formatContext->duration / AV_TIME_BASE;
    } else {
        return 0.0f;
    }
}

- (CGFloat)startTime {
    if (self.videoStreamIndex != -1) {
        AVStream *st = _formatContext->streams[self.videoStreamIndex];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _videoTimeBase;
        return 0;
    }
    
    if (self.audioStreamIndex != -1) {
        AVStream *st = _formatContext->streams[self.audioStreamIndex];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _audioTimeBase;
        return 0;
    }
    return 0;
}

- (CGFloat)fps {
    return self.videoFps;
}

- (BOOL)hasVideo {
    return self.videoStreamIndex != -1;
}

- (BOOL)hasAudio {
    return self.audioStreamIndex != -1;
}

- (void)setupAsset:(NSError **) error {
    self.formatContext = avformat_alloc_context();
    if (self.formatContext == NULL) {
        *error = [NSError errorWithDomain:FFmpegOC_formatContext code:1 userInfo:nil];
        return;
    }
    
    if (avformat_open_input(&_formatContext, self.url.absoluteString.UTF8String, NULL, NULL) != 0) {
        *error = [NSError errorWithDomain:FFmpegOC_openInput code:1 userInfo:nil];
        return;
    }
    
    if (avformat_find_stream_info(_formatContext, NULL) < 0) {
        *error = [NSError errorWithDomain:FFmpegOC_findStream code:1 userInfo:nil];
        return;
    }
    
#ifdef DEBUG
    av_dump_format(_formatContext, 0, _formatContext->url, 0);
#endif
    
    [self setupCodecs: error];
}

- (void)setupCodecs:(NSError **)error {
    for(int i = 0; i< _formatContext->nb_streams; i++) {
        AVCodecParameters *codecParam = self.formatContext->streams[i]->codecpar;
        switch (codecParam->codec_type) {
            case AVMEDIA_TYPE_VIDEO:
                if (self.videoCodec == NULL) {
                    self.videoCodec = avcodec_find_decoder(codecParam->codec_id);
                    self.videoCodecParam = codecParam;
                    self.videoStreamIndex = i;
                } else {
                    assert(0);
                }
                break;
            case AVMEDIA_TYPE_AUDIO:
                if (self.audioCodec == NULL) {
                    self.audioCodec = avcodec_find_decoder(codecParam->codec_id);
                    self.audioCodecParam = codecParam;
                    self.audioStreamIndex = i;
                } else {
                    assert(0);
                }
                break;
            default:
                break;
        }
    }
    NSAssert(self.videoStreamIndex != -1, @"No video stream");
    
    if (_audioStreamIndex != -1 && *error == nil) {
        [self setupAudioCodec:error];
    }
    
    if (_videoStreamIndex != -1 && *error == nil) {
        [self setupVideoCodec:error];
    }
}

- (void)setupVideoCodec:(NSError **)error {
    if (self.videoCodec == NULL) {
        *error = [NSError errorWithDomain:FFmpegOC_noVideoCodec code:0 userInfo:nil];
        return;
    }
    
    self.videoCodecCtx = avcodec_alloc_context3(self.videoCodec);
    if (self.videoCodecCtx == NULL) {
        *error = [NSError errorWithDomain:FFmpegOC_videoCodecCtx code:1 userInfo:nil];
        return;
    }
    
    if (self.videoCodecParam != NULL) {
        if (avcodec_parameters_to_context(self.videoCodecCtx, self.videoCodecParam) < 0) {
            *error = [NSError errorWithDomain:FFmpegOC_videoCodecCtx_codecParams code:1 userInfo:nil];
            return;
        }
    }
    
    if (avcodec_open2(self.videoCodecCtx, self.videoCodec, NULL) < 0) {
        *error = [NSError errorWithDomain:FFmpegOC_openVideoCodec code:1 userInfo:nil];
        return;
    }
    
    
    self.videoStream = _formatContext->streams[self.videoStreamIndex];
    avStreamFPSTimeBase(self.videoStream, 0.04, &_videoFps, &_videoTimeBase);
}

- (void)setupAudioCodec:(NSError **)error {
    if (self.audioCodec == NULL) {
        *error = [NSError errorWithDomain:FFmpegOC_noAudioCodec code:0 userInfo:nil];
        return;
    }
    
    
    self.audioCodecCtx = avcodec_alloc_context3(self.audioCodec);
    if (self.audioCodecCtx == NULL) {
        *error = [NSError errorWithDomain:FFmpegOC_audioCodecCtx code:1 userInfo:nil];
        return;
    }
    
    if (avcodec_parameters_to_context(self.audioCodecCtx, self.audioCodecParam) < 0) {
        *error = [NSError errorWithDomain:FFmpegOC_audioCodecCtx_codecParams code:1 userInfo:nil];
        return;
    }

    if (avcodec_open2(self.audioCodecCtx, self.audioCodec, NULL) < 0) {
        *error = [NSError errorWithDomain:FFmpegOC_openAudioCodec code:1 userInfo:nil];
        return;
    }
    
    self.audioStream = _formatContext->streams[self.audioStreamIndex];
    avStreamFPSTimeBase(self.audioStream, 0.025, 0, &_audioTimeBase);
}

- (NSString *)description
{
    if(self.formatContext == NULL) { return @"Invalid format context"; }
    int64_t tns, thh, tmm, tss;
    tns  = (_formatContext->duration)/1000000;
    thh  = tns / 3600;
    tmm  = (tns % 3600) / 60;
    tss  = (tns % 60);
    return [NSString stringWithFormat:@"Format %s, duration %02lld:%02lld:%02lld", _formatContext->iformat->long_name, thh,tmm,tss];
}



static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;

    if (st->time_base.num && st->time_base.den)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.num && st->codec->time_base.den)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        NSLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.num && st->avg_frame_rate.den)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.num && st->r_frame_rate.den)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}
@end
