////
////  AssetInfoReader.cpp
////  FFmpegRTVE
////
////  Created by weidong fu on 2019/7/12.
////  Copyright © 2019 weidong fu. All rights reserved.
////
//
//#include "FFAssetReader.hpp"
//#include <assert.h>
//
//FFAssetReader::FFAssetReader(char * fileURL) {
//    this->pFormatContext = avformat_alloc_context();
//    if (this->pFormatContext == NULL) {
//        printf("Could not allcate memory for pFormatContext");
//    }
//
//    if (avformat_open_input(&pFormatContext, fileURL, NULL, NULL) != 0) {
//        printf("Could not open file: %s", fileURL);
//    }
//
//    if(avformat_find_stream_info(pFormatContext,  NULL) < 0) {
//        printf("ERROR could not get the stream info");
//        return;
//    }
//
//    for (int i = 0; i < pFormatContext->nb_streams; i++) {
//        AVCodecParameters *codecParam = pFormatContext->streams[i]->codecpar;
//        switch (codecParam->codec_type) {
//            case AVMEDIA_TYPE_VIDEO:
//                if (this->videoCodec == NULL) {
//                    this->videoCodec = avcodec_find_decoder(codecParam->codec_id);
//                    this->videoCodecParam = codecParam;
//                } else {
//                    assert(0);
//                }
//                break;
//            case AVMEDIA_TYPE_AUDIO:
//                if (this->audioCodec == NULL) {
//                    this->audioCodec = avcodec_find_decoder(codecParam->codec_id);
//                    this->audioCodecParam = codecParam;
//                } else {
//                    assert(0);
//                }
//                break;
//            default:
//                break;
//        }
//    }
//}
//
//FFAssetReader::~FFAssetReader() {
//    avformat_close_input(&pFormatContext);
//    avformat_free_context(this->pFormatContext);
//
//    avcodec_free_context(&videoCodecCtx);
//    avcodec_free_context(&audioCodecCtx);
//}
//
//void FFAssetReader::setupVideoCodecContext() {
//    this->videoCodecCtx = avcodec_alloc_context3(this->videoCodec);
//    if (!videoCodecCtx) {
//        assert(0);
//    }
//
//    if (avcodec_parameters_to_context(this->videoCodecCtx, this->videoCodecParam) < 0) {
//        printf("faild to copy codec params to video codec context");
//        assert(0);
//    }
//
//    if (avcodec_open2(this->videoCodecCtx, this->videoCodec, NULL) < 0) {
//        printf("failed to open codec through avcodec_open2");
//        assert(0);
//    }
//}
//
//void FFAssetReader::setupAudioCodecContext() {
//    this->audioCodecCtx = avcodec_alloc_context3(this->audioCodec);
//    if (!audioCodecCtx) {
//        assert(0);
//    }
//
//    if (avcodec_parameters_to_context(this->audioCodecCtx, this->audioCodecParam) < 0) {
//        printf("faild to copy codec params to video codec context");
//        assert(0);
//    }
//
//    if (avcodec_open2(this->audioCodecCtx, this->audioCodec, NULL) < 0) {
//        printf("failed to open codec through avcodec_open2");
//        assert(0);
//    }
//}
//
//void FFAssetReader::printAssetInfo() {
//    av_dump_format(pFormatContext, 0, pFormatContext->url, 0);
//    int64_t tns, thh, tmm, tss;
//    tns  = (pFormatContext->duration)/1000000;
//    thh  = tns / 3600;
//    tmm  = (tns % 3600) / 60;
//    tss  = (tns % 60);
//    printf("Format %s, duration %02lld:%02lld:%02lld", pFormatContext->iformat->long_name, thh,tmm,tss);
//}
