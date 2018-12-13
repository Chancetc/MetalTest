//
//  QGHWDMP4OpenGLView.h
//  QGame
//
//  Created by Chanceguo on 2017/3/2.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "UIView+MP4HWDecode.h"

@protocol QGHWDMP4OpenGLViewDelegate <NSObject>

- (void)onViewUnavailableStatus;

@end

@interface QGHWDMP4OpenGLView : UIView

@property (nonatomic, weak) id<QGHWDMP4OpenGLViewDelegate> displayDelegate;

@property (nonatomic, assign) QGHWDTextureBlendMode blendMode;

@property (nonatomic, assign) BOOL pause;

/**
 初始化opengl环境
 */
- (void)setupGL;

/**
 上屏

 @param pixelBuffer 硬解出来的samplebuffer数据
 */
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
