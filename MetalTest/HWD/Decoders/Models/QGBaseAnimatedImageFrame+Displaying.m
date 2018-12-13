//
//  QGBaseAnimatedImageFrame+Displaying.m
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGBaseAnimatedImageFrame+Displaying.h"
#import <objc/runtime.h>

@implementation QGBaseAnimatedImageFrame (Displaying)

- (void)setStartDate:(NSDate *)startDate {
    objc_setAssociatedObject(self, @"startDate", startDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)startDate {
    return objc_getAssociatedObject(self, @"startDate");
}

- (void)setDecodeTime:(NSTimeInterval)decodeTime {
    objc_setAssociatedObject(self, @"decodeTime", @(decodeTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)decodeTime {
    return [objc_getAssociatedObject(self, @"decodeTime") doubleValue];
}

- (BOOL)shouldFinishDisplaying {

    if (!self.startDate) {
        return YES;
    }
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.startDate];
    //每一个VSYNC16ms
    return timeInterval*1000 + 10 >= self.duration;
}

@end
