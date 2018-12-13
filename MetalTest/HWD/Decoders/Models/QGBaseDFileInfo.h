//
//  QGBaseDFileInfo.h
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QGBaseDFileInfo : NSObject

@property (nonatomic, strong) NSString *filePath;      //文件路径

@property (atomic, assign) NSInteger occupiedCount;    //作用类似retainCount

@end
