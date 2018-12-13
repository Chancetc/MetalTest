//
//  QGAnimatedImageDecodeThreadPool.m
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGAnimatedImageDecodeThreadPool.h"
#import "QGAnimatedImageDecodeThread.h"
#import "QGSafeMutableArray.h"

@interface QGAnimatedImageDecodeThreadPool (){

    NSMutableArray *_threads;
}

@end

@implementation QGAnimatedImageDecodeThreadPool

+ (instancetype)sharedPool {

    static QGAnimatedImageDecodeThreadPool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QGAnimatedImageDecodeThreadPool alloc] init];
    });
    return instance;
}

- (instancetype)init {

    if (self = [super init]) {
        _threads = [QGSafeMutableArray new];
    }
    return self;
}

- (QGAnimatedImageDecodeThread *)getDecodeThread {

    QGAnimatedImageDecodeThread *freeThread = nil;
    for (QGAnimatedImageDecodeThread *thread in _threads) {
        if (!thread.occupied) {
            freeThread = thread;
        }
    }
    if (!freeThread) {
        freeThread = [[QGAnimatedImageDecodeThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [freeThread start];
        [_threads addObject:freeThread];
    }
    return freeThread;
}

- (void)run{
    //线程保活
    @autoreleasepool {
        [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    }
}

@end
