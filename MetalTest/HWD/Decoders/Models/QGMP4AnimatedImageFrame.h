//
//  QGMP4AnimatedImageFrame.h
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGBaseAnimatedImageFrame.h"
#import <CoreVideo/CoreVideo.h>

@interface QGMP4AnimatedImageFrame : QGBaseAnimatedImageFrame

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@property (nonatomic, assign) int defaultFps;

@end
