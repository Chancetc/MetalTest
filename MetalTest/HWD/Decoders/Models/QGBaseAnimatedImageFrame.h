//
//  QGBaseAnimatedImageFrame.h
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QGBaseAnimatedImageFrame : NSObject

@property (nonatomic, assign) NSInteger frameIndex;         //当前帧索引

@property (nonatomic, assign) NSTimeInterval duration;      //播放时长

@end
