//
//  QGWeakProxy.m
//  QGame
//
//  Created by jackjhu on 3/11/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import "QGWeakProxy.h"

@implementation QGWeakProxy {
    __weak id _target;
}

- (instancetype)initWithTarget:(id)target {
    if (self = [super init]) {
        _target = target;
    }
    return self;
}

+ (instancetype)proxyWithTarget:(id)target {
    return [[QGWeakProxy alloc] initWithTarget:target];
}

// 1. 快速消息转发
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _target;
}

// 2. 如果<1>返回nil，到标准消息转发处理，如果不处理为Crash：unrecognized selector. 这里我们直接返回空指针地址.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    void *null = NULL;
    [anInvocation setReturnValue:&null];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

@end
