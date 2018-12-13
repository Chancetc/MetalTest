//
//  QGAnimatedImageDecodeManager.h
//  QGame
//
//  Created by Chanceguo on 17/2/13.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QGBaseDecoder.h"
#import "QGBaseAnimatedImageFrame.h"
#import "QGAnimatedImageDecodeConfig.h"

@class QGAnimatedImageDecodeManager;
@protocol QGAnimatedImageDecoderDelegate <NSObject>


/**
 必须实现该方法 用以实例化解码器

 @param manager 解码控制器
 @return class
 */
- (Class)decoderClassForManager:(QGAnimatedImageDecodeManager *)manager;

@optional


/**
 到文件末尾时被调用

 @param decoder <#decoder description#>
 */
- (void)decoderDidFinishDecode:(QGBaseDecoder *)decoder;

- (void)decoderDidFailDecode:(QGBaseDecoder *)decoder error:(NSError *)error;

@end

@interface QGAnimatedImageDecodeManager : NSObject

@property (nonatomic, weak) id<QGAnimatedImageDecoderDelegate> decoderDelegate;

- (instancetype)initWith:(QGBaseDFileInfo *)fileInfo
                  config:(QGAnimatedImageDecodeConfig *)config
                delegate:(id<QGAnimatedImageDecoderDelegate>)delegate;

/**
 取出已解码的一帧并准备下一帧

 @param frameIndex 帧索引
 @return 帧内容
 */
- (QGBaseAnimatedImageFrame *)consumeDecodedFrame:(NSInteger)frameIndex;

@end
