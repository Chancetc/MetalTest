//
//  QGAnimatedImageDecodeManager.m
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGAnimatedImageDecodeManager.h"
#import "QGAnimatedImageBufferManager.h"
#import "QGBaseDecoder.h"
#import "QGSafeMutableArray.h"
#import <sys/stat.h>

@interface QGAnimatedImageDecodeManager() {

    QGAnimatedImageDecodeConfig *_config;           //解码配置
    QGBaseDFileInfo *_fileInfo;                     //sharpP文件信息
    NSMutableArray *_decoders;                      //解码器
    QGAnimatedImageBufferManager *_bufferManager;   //缓冲管理
}

@end

@implementation QGAnimatedImageDecodeManager

- (instancetype)initWith:(QGBaseDFileInfo *)fileInfo
                  config:(QGAnimatedImageDecodeConfig *)config
                delegate:(id<QGAnimatedImageDecoderDelegate>)delegate {

    if (self = [super init]) {
        
        _config = config;
        _fileInfo = fileInfo;
        _decoderDelegate = delegate;
        [self createDecodersByConfig:config];
        _bufferManager = [[QGAnimatedImageBufferManager alloc] initWithConfig:config];
        [self initializeBuffers];
    }
    return self;
}

- (QGBaseAnimatedImageFrame *)consumeDecodedFrame:(NSInteger)frameIndex {

    @synchronized (self) {
        if (frameIndex==0 && ![_bufferManager isBufferFull]) {
            return nil;
        }
        [self checkIfDecodeFinish:frameIndex];
        QGBaseAnimatedImageFrame *frame = [_bufferManager getBufferedFrame:frameIndex];
        if (frame && frame.frameIndex == frameIndex) {
            [self decodeFrame:frame.frameIndex+_bufferManager.buffers.count];
        }
        return frame;
    }
}

#pragma mark - private methods

- (void)checkIfDecodeFinish:(NSInteger)frameIndex {
    
    NSInteger decoderIndex = _decoders.count==1?0:frameIndex%_decoders.count;
    QGBaseDecoder *decoder = _decoders[decoderIndex];
    if ([decoder isFrameIndexBeyondEnd:frameIndex]) {
        if ([self.decoderDelegate respondsToSelector:@selector(decoderDidFinishDecode:)]) {
            [self.decoderDelegate decoderDidFinishDecode:decoder];
        }
    }
}

- (void)decodeFrame:(NSInteger)frameIndex {

    if (!_decoders || _decoders.count == 0) {
        //QG_Info(MODULE_SHARPP,@"error! can't find decoder");
        return ;
    }
    NSInteger decoderIndex = _decoders.count==1?0:frameIndex%_decoders.count;
    QGBaseDecoder *decoder = _decoders[decoderIndex];
    if ([decoder shouldStopDecode:frameIndex]) {
        return ;
    }
    [decoder decodeFrame:frameIndex buffers:_bufferManager.buffers];
}

- (void)createDecodersByConfig:(QGAnimatedImageDecodeConfig *)config {

    if (!self.decoderDelegate || ![self.decoderDelegate respondsToSelector:@selector(decoderClassForManager:)]) {
        //QG_Event(MODULE_DECODE, @"you MUST implement the delegate in invoker!");
        NSAssert(0, @"you MUST implement the delegate in invoker!");
        return ;
    }
    
    _decoders = [QGSafeMutableArray new];
    for (int i = 0; i < config.threadCount; i ++) {
        Class class = [self.decoderDelegate decoderClassForManager:self];
        NSError *error = nil;
        QGBaseDecoder *decoder = [class alloc];
        decoder = [decoder initWith:_fileInfo error:&error];
        if (!decoder) {
            if ([self.decoderDelegate respondsToSelector:@selector(decoderDidFailDecode:error:)]) {
                [self.decoderDelegate decoderDidFailDecode:nil error:error];
            }
            break ;
        }
        [_decoders addObject:decoder];
    }
}

- (void)initializeBuffers {
    
    for (int i = 0; i < _bufferManager.buffers.count; i++) {
        [self decodeFrame:i];
    }
}

- (void)dealloc {

}

@end
