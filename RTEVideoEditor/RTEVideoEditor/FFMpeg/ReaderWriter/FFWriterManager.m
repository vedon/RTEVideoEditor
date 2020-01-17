//
//  FFWriterManager.m
//  FFmpegOC
//
//  Created by weidong fu on 2019/8/26.
//

#import "FFWriterManager.h"

@implementation FFWriterManager
//void SaveFrame(AVFrame *pFrame, int width, int height, int iFrame) {
//    FILE *pFile;
//    char szFilename[32];
//    int y;
//
//    // Open file.
//    sprintf(szFilename, "frame%d.ppm", iFrame);
//    pFile = fopen(szFilename, "wb");
//    if (pFile == NULL) {
//        return;
//    }
//
//    // Write header.
//    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
//
//    // Write pixel data.
//    for (y = 0; y < height; y++) {
//        fwrite(pFrame->data[0]+y*pFrame->linesize[0], 1, width*3, pFile);
//    }
//
//    // Close file.
//    fclose(pFile);
//}
@end
