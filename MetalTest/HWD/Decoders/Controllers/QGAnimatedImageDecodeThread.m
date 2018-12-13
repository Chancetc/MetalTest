//
//  QGAnimatedImageDecodeThread.m
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "QGAnimatedImageDecodeThread.h"

@implementation QGAnimatedImageDecodeThread

- (NSString *)sequenceDec
{
#ifdef DEBUG
    return [NSString stringWithFormat:@"%@",@([[self valueForKeyPath:@"private.seqNum"] integerValue])];//
#else
    return [self description];
#endif
}

@end
