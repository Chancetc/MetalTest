//
//  QGAnimatedImageBufferManager.m
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGAnimatedImageBufferManager.h"
#import "QGSafeMutableArray.h"

@interface QGAnimatedImageBufferManager() {

    QGAnimatedImageDecodeConfig *_config;       //解码配置
}

@end

@implementation QGAnimatedImageBufferManager

- (instancetype)initWithConfig:(QGAnimatedImageDecodeConfig *)config {

    if (self = [super init]) {
        _config = config;
        [self createBuffersWithConfig:config];
    }
    return self;
}

- (void)createBuffersWithConfig:(QGAnimatedImageDecodeConfig *)config {
    
    _buffers = [QGSafeMutableArray new];
    for (int i = 0; i < config.bufferCount; i++) {
        NSObject *frame = [NSObject new];
        [_buffers addObject:frame];
    }
}

- (QGBaseAnimatedImageFrame *)getBufferedFrame:(NSInteger)frameIndex {

    if (_buffers.count == 0) {
        //QG_Info(MODULE_SHARPP,@"fail buffer is nil");
        return nil;
    }
    NSInteger bufferIndex = frameIndex%_buffers.count;
    if (bufferIndex > _buffers.count-1) {
        //QG_Info(MODULE_SHARPP,@"fail");
        return nil;
    }
    id frame = [_buffers objectAtIndex:bufferIndex];
    if (![frame isKindOfClass:[QGBaseAnimatedImageFrame class]] || ([(QGBaseAnimatedImageFrame*)frame frameIndex] != frameIndex)) {
        return nil;
    }
    return frame;
}

- (BOOL)isBufferFull {

    __block BOOL isFull = YES;
    [_buffers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[QGBaseAnimatedImageFrame class]]) {
            isFull = NO;
            *stop = YES;
        }
    }];
    return isFull;
}

- (void)dealloc {

}

@end
