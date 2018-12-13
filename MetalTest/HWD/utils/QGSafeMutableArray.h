//
//  QGSafeMutableArray.h
//  QGame
//
//  Created by Chance_xmu on 16/12/8.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 This class inherits from NSMutableArray,make it tread safe and allow Recursive lock.
 
 @discussion access performance would lower than NSMutableArray, or using semaphore but equal to @sychronized.
 
 @warning Fast enumerate and enumerator are not thread safe
 */
@interface QGSafeMutableArray : NSMutableArray

@end
