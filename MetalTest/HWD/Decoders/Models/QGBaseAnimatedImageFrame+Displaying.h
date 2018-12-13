//
//  QGBaseAnimatedImageFrame+Displaying.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGBaseAnimatedImageFrame.h"

@interface QGBaseAnimatedImageFrame (Displaying)

@property (nonatomic, strong) NSDate *startDate; //开始播放的时间

@property (nonatomic, assign) NSTimeInterval decodeTime; //解码时间

- (BOOL)shouldFinishDisplaying;     //是否需要结束播放（根据播放时长来决定）

@end
