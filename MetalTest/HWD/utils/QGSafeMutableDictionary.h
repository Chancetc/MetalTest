//
//  QGSafeMutableDictionary.h
//  QGame
//
//  Created by Chanceguo on 16/12/8.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This class inherits from NSMutableDictionary, make it thread safe and allow Recursive lock.
 
 @discussion access performance would lower than NSMutableDictionary, or using semaphore but equal to @sychronized.
 
 @warning Fast enumerate and enumerator are not thread safe
 */
@interface QGSafeMutableDictionary : NSMutableDictionary

@end
