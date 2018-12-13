//
//  QGAnimatedImageBufferManager.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QGAnimatedImageDecodeConfig.h"
#import "QGBaseAnimatedImageFrame.h"

@interface QGAnimatedImageBufferManager : NSObject


/**
 缓冲
 */
@property (nonatomic, strong) NSMutableArray *buffers;

- (instancetype)initWithConfig:(QGAnimatedImageDecodeConfig *)config;


/**
 取出指定的在缓冲区的帧，若不存在于缓冲区则返回空

 @param frameIndex 目标帧索引
 @return 帧数据
 */
- (QGBaseAnimatedImageFrame *)getBufferedFrame:(NSInteger)frameIndex;


/**
 判断当前缓冲区是否被填满

 @return 只有当缓冲区所有区域都被QGBaseAnimatedImageFrame类型的数据填满才算缓冲区满
 */
- (BOOL)isBufferFull;

@end
