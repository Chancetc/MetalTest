//
//  QGBaseDecoder.h
//  QGame
//  解码器
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QGAnimatedImageDecodeThread.h"
#import "QGBaseDFileInfo.h"

@interface QGBaseDecoder : NSObject

@property (nonatomic, strong) QGAnimatedImageDecodeThread *decodeThread;   //解码线程

@property (atomic, assign) NSInteger currentDecodeFrame;    //正在解码的帧索引

@property (nonatomic, readonly) QGBaseDFileInfo *fileInfo; //解码文件信息 只能通过初始化方法赋值

- (instancetype)initWith:(QGBaseDFileInfo *)fileInfo error:(NSError **)error;

/**
 在专用线程内解码指定帧并放入对应的缓冲区内
 
 @param frameIndex 帧索引
 @param buffers 缓冲
 */
- (void)decodeFrame:(NSInteger)frameIndex buffers:(NSMutableArray *)buffers;


/**
 由具体子类实现
 该方法在decodeframe方法即将被调用时调用，如果返回YES则停止解码工作

 @param nextFrameIndex 将要解码的帧索引
 @return 是否需要继续解码
 */
- (BOOL)shouldStopDecode:(NSInteger)nextFrameIndex;

- (BOOL)isFrameIndexBeyondEnd:(NSInteger)frameIndex;

@end
