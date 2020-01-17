//
//  FFConvert.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/27.
// https://ffmpeg.org/doxygen/2.8/ffmpeg__videotoolbox_8c_source.html
// AVFrame to CVPixelBuffer
// https://www.twblogs.net/a/5b7e49342b71776838566751
// https://stackoverflow.com/questions/15258290/how-to-convert-an-ffmpeg-avframe-in-yuvj420p-to-avfoundation-cvpixelbufferref?rq=1
// https://chromium.googlesource.com/chromium/third_party/ffmpeg/+/master-backup/libavcodec/vda_h264_dec.c
//
// 硬解 https://www.cnblogs.com/isItOk/p/5964639.html 读取pixelbuffer
// yuv planar
//https://software.intel.com/en-us/ipp-dev-reference-pixel-and-planar-image-formats
//https://stackoverflow.com/questions/27822017/planar-yuv420-data-layout

#import "FFConvert.h"
#import <Foundation/Foundation.h>

@implementation FFConvert
//https://glumes.com/post/ffmpeg/understand-yuv-format/
//http://www.raomengyang.com/2016/06/13/DifferenceOfYUV/
// https://stackoverflow.com/questions/25659671/how-to-convert-from-yuv-to-ciimage-for-ios
/*
 像素格式名称后面有“P”的，代表是planar格式，否则就是packed格式
 像素格式名称后面有“BE”的，代表是Big Endian格式；名称后面有“LE”的，代表是Little Endian格式。
 
 YUV420P，Y，U，V三个分量都是平面格式，分为I420和YV12。I420格式和YV12格式的不同处在U平面和V平面的位置不同。在I420格式中，U平面紧跟在Y平面之后，然后才是V平面（即：YUV）；但YV12则是相反（即：YVU）。
 
 Planar 平面格式,指先连续存储所有像素点的 Y 分量，然后存储 U 分量，最后是 V 分量。
 I420(YU 12): YYYYYYYY UU VV    =>YUV420P
 YV12: YYYYYYYY VV UU    =>YUV420P
 
 data[0]: Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8……
 data[1]: U1, U2, U3, U4……
 data[2]: V1, V2, V3, V4……
 
 
 NV12 和 NV21 格式都属于 YUV420SP 类型。它也是先存储了 Y 分量，但接下来并不是再存储所有的 U 或者 V 分量，而是把 UV 分量交替连续存储。（YUV420SP, Y分量平面格式，UV打包格式, 即NV12）
 
 1）NV12 是 IOS 中有的模式，它的存储顺序是先存 Y 分量，再 UV 进行交替存储。
 NV12: YYYYYYYY UVUV     =>YUV420SP
 data[0]: Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8……
 data[1]: U，V, U，V, U,V, U,V……
 
 2）NV21 是 安卓 中有的模式，它的存储顺序是先存 Y 分量，在 VU 交替存储。
 NV21: YYYYYYYY VUVU     =>YUV420SP
 
 data[0]: Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8……
 data[1]: V, U，V, U, V, U...
 
 */
+ (void)convertAVFrame:(AVFrame *)frame toPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if(pixelBuffer == nil)  return;
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    switch (frame->format) {
        case AV_PIX_FMT_YUV420P:
        case AV_PIX_FMT_YUVJ420P:
        {
            size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
            void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            memcpy(base, frame->data[0], bytePerRowY * frame->height);
            base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
            
            uint32_t size = frame->linesize[1] * frame->height;
            size_t dataSize =  2 * size;
            uint8_t* dstData = (uint8_t*)malloc(dataSize);
            NSAssert(frame->linesize[1] == frame->linesize[2], @"Invalid line size");
            for (int i = 0; i <dataSize; i++){
                if (i % 2 == 0){
                    dstData[i] = frame->data[1][i/2];
                }else {
                    dstData[i] = frame->data[2][i/2];
                }
            }
            memcpy(base, dstData, size);
            free(dstData);
        }
            break;
            
        case AV_PIX_FMT_NV12:
        {
            size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
            size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
            void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            memcpy(base, frame->data[0], bytePerRowY * frame->height);
            base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
            memcpy(base, frame->data[1], bytesPerRowUV * frame->height/2);
            break;
        }
        case AV_PIX_FMT_RGB24:
        {
            /*
             data[0]: R1, G1, B1, R2, G2, B2, R3, G3, B3, R4, G4, B4……
             */
            break;
        }
        default:
            NSAssert(false, @"Unspported");
            break;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

//CVPixelBuffer to AVFrame https://ffmpeg.org/doxygen/2.8/ffmpeg__videotoolbox_8c_source.html
@end
