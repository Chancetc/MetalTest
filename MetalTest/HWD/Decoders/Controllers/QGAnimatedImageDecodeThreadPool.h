//
//  QGAnimatedImageDecodeThreadPool.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QGAnimatedImageDecodeThread.h"

@interface QGAnimatedImageDecodeThreadPool : NSObject

+ (instancetype)sharedPool;


/**
 从池子中找出没被占用的线程，如果没有则新建一个

 @return 解码线程
 */
- (QGAnimatedImageDecodeThread *)getDecodeThread;

@end
