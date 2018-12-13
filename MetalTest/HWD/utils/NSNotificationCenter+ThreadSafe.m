//
//  NSNotificationCenter+ThreadSafe.m
//  releaseTest
//
//  Created by Chanceguo on 17/1/10.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "NSNotificationCenter+ThreadSafe.h"
#import "QGSafeMutableDictionary.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface NSObject (SafeNotification)

@property (nonatomic, strong) NSOperationQueue *notificationOperationQueue;

@end

@implementation NSObject (SafeNotification)

- (NSOperationQueue *)notificationOperationQueue {
    @synchronized (self) {
        NSOperationQueue *queue = objc_getAssociatedObject(self, @"notificationOperationQueue");
        if (!queue) {
            queue = [[NSOperationQueue alloc] init];
            queue.maxConcurrentOperationCount = 1;
            self.notificationOperationQueue = queue;
        }
        return queue;
    }
}

- (void)setNotificationOperationQueue:(NSOperationQueue *)notificationOperationQueue {
    @synchronized (self) {
        objc_setAssociatedObject(self, @"notificationOperationQueue", notificationOperationQueue, OBJC_ASSOCIATION_RETAIN);
    }
}

@end

@implementation NSNotificationCenter (ThreadSafe)

- (void)addSafeObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject {
    
    double sysVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];;
    if (sysVersion >= 9.0) {
        return [self addObserver:observer selector:aSelector name:aName object:anObject];
    }
    __weak typeof(observer) weakObserver = observer;
    __block NSObject *blockObserver = [self addObserverForName:aName object:anObject queue:aName.notificationOperationQueue usingBlock:^(NSNotification * _Nonnull note) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        __strong __typeof__(weakObserver) strongObserver = weakObserver;
        [strongObserver performSelector:aSelector withObject:note];
#pragma clang diagnostic pop
        if (!weakObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:blockObserver];
            blockObserver = nil;
        }
    }];
}
- (void)addWeakObserver:( id)Observer name:(NSNotificationName)aName usingBlock:(void (^)(NSNotification *note,id observer))block{
    __weak id weakObserver=Observer;
    __block NSObject *blockObserver = [self addObserverForName:aName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
         __strong id strongObserver = weakObserver;
        if(!weakObserver ){
            [[NSNotificationCenter defaultCenter] removeObserver:blockObserver];
            blockObserver = nil;
        }else{
            block(note,strongObserver);
        }
    
    }];
}
- (void)addSafeObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject queue:(NSOperationQueue *)queue {

    aName.notificationOperationQueue = queue;
    [self addSafeObserver:observer selector:aSelector name:aName object:anObject];
}

@end
