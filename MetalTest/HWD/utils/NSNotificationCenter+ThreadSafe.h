//
//  NSNotificationCenter+ThreadSafe.h
//  releaseTest
//
//  Created by Chanceguo on 17/1/10.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (ThreadSafe)


/**
 该方法能够保证通知的执行和移除是线程安全的
 不需要手动移除通知
 (iOS9以下系统方法addObserver:selector:name:object:通常用法是不安全的。
 
 @note 该方法适用于代替原来需要在dealloc内移除通知的场景

 @param observer  Object registering as an observer. This value must not be nil.
 @param aSelector Selector that specifies the message the receiver sends observer to notify it of the notification posting. The method specified by aSelector must have one and only one argument (an instance of NSNotification).
 @param aName     The name of the notification for which to register the observer; that is, only notifications with this name are delivered to the observer.
 If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.
 @param anObject  The object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
 If you pass nil, the notification center doesn’t use a notification’s sender to decide whether to deliver it to the observer.
 */
- (void)addSafeObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject;
- (void)addWeakObserver:( id)weakObserver name:(NSNotificationName)aName usingBlock:(void (^)(NSNotification *note,id observer))block;


/**
 1.设置接收通知的queue
 2.调用- (void)addSafeObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject

 @param observer  Object registering as an observer. This value must not be nil.
 @param aSelector Selector that specifies the message the receiver sends observer to notify it of the notification posting. The method specified by aSelector must have one and only one argument (an instance of NSNotification).
 @param aName     The name of the notification for which to register the observer; that is, only notifications with this name are delivered to the observer.
 If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.
 @param anObject  The object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
 If you pass nil, the notification center doesn’t use a notification’s sender to decide whether to deliver it to the observer.
 @param queue The operation queue to which callbackoperation should be added.
 If you pass nil, the block is run asynchronously on queue which hold by this notification.
 */
- (void)addSafeObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject queue:(NSOperationQueue *)queue;

@end
