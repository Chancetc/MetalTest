//
//  QGWeakProxy.h
//  QGame
//
//  Created by jackjhu on 3/11/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QGWeakProxy : NSObject

- (instancetype)initWithTarget:(id)target;

+ (instancetype)proxyWithTarget:(id)target;

@end
