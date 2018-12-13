//
//  QGMP4AnimatedImageFrame.m
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGMP4AnimatedImageFrame.h"

@implementation QGMP4AnimatedImageFrame

- (void)dealloc {

    //释放image buffer
    if (self.pixelBuffer) {
        CVPixelBufferRelease(self.pixelBuffer);
    }
}

@end
