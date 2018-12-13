//
//  QGAnimatedImageDecodeThread.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QGAnimatedImageDecodeThread : NSThread

@property (nonatomic, assign) BOOL occupied; //是否被解码器占用

@property (nonatomic, readonly) NSString *sequenceDec; //线程标识信息

@end
