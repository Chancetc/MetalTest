//
//  QGAnimatedImageDecodeConfig.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QGAnimatedImageDecodeConfig : NSObject

//线程数
@property (nonatomic, assign) NSInteger threadCount;

//缓冲数
@property (nonatomic, assign) NSInteger bufferCount;

@end
