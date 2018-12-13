//
//  QGBaseDecoder.m
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGBaseDecoder.h"
#import "QGAnimatedImageDecodeThreadPool.h"

@interface QGBaseDecoder() {

    QGBaseDFileInfo *_fileInfo;
}

@end

@implementation QGBaseDecoder

- (instancetype)initWith:(QGBaseDFileInfo *)fileInfo error:(NSError **)error {
    
    if (self = [super init]) {
        _currentDecodeFrame = -1;
        _fileInfo = fileInfo;
        _fileInfo.occupiedCount ++;
        _decodeThread = [[QGAnimatedImageDecodeThreadPool sharedPool] getDecodeThread];
        _decodeThread.occupied = YES;
    }
    return self;
}

- (QGBaseDFileInfo *)fileInfo {
    
    return _fileInfo;
}

- (BOOL)shouldStopDecode:(NSInteger)nextFrameIndex {
    // No implementation here. Meant to be overriden in subclass.
    return NO;
}

- (BOOL)isFrameIndexBeyondEnd:(NSInteger)frameIndex {
    
    return NO;
}

- (void)decodeFrame:(NSInteger)frameIndex buffers:(NSMutableArray *)buffers {
    // No implementation here. Meant to be overriden in subclass.
}

@end
