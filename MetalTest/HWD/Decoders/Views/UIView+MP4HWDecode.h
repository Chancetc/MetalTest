//
//  UIView+MP4HWDecode.h
//  QGame
//
//  Created by Chanceguo on 17/2/28.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QGMP4AnimatedImageFrame.h"
#import "QGBaseAnimatedImageFrame+Displaying.h"

@class QGMP4AnimatedImageFrame, QGAdvancedGiftAttachmentsConfigModel;

extern NSInteger const QGMP4HWDDefaultFPS;      //默认fps 25
extern NSInteger const QGMP4HWDMinFPS;          //最小fps 1
extern NSInteger const QGMP4HWDMaxFPS;          //最大fps 60

/* 数字跳动的动画类型*/
typedef NS_ENUM(NSInteger, QGHWDTextureBlendMode){
    
    QGHWDTextureBlendMode_AlphaLeft                 = 0,          // 左侧alpha
    QGHWDTextureBlendMode_AlphaRight                = 1,          // 右侧alpha
    QGHWDTextureBlendMode_AlphaTop                  = 2,          // 上侧alpha
    QGHWDTextureBlendMode_AlphaBottom               = 3,          // 下测alpha
};

@protocol HWDMP4PlayDelegate <NSObject>

/**
 called when a new frame was flushed to screen.

 @param frame flushed frame
 @param container current view that invoke playing func.
 */
- (void)viewDidPlayMP4AtFrame:(QGMP4AnimatedImageFrame*)frame view:(UIView *)container;


/**
 called when playing process was paused or finish.

 @param lastFrameIndex the last frame index before animation stop.
 @param container <#container description#>
 */
- (void)viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(UIView *)container;


/**
 called when decoding and playing process are finished.

 @param totalFrameCount the count of frames that played
 @param container <#container description#>
 */
- (void)viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(UIView *)container;

@optional

- (void)viewDidFailPlayMP4:(NSError *)error;

@end

@interface UIView (MP4HWDecode)

@property (nonatomic, readonly) QGMP4AnimatedImageFrame *currentHWDFrame; //readonly, you must not change the value directly

@property (nonatomic, strong) NSString *MP4FilePath;

@property (nonatomic, assign) NSInteger HWDFps;         //fps for dipslay, each frame's duration would be set by fps value before display.

@property (nonatomic, weak) id<HWDMP4PlayDelegate> MP4PlayDelegate;


/**
 call method: playHWDMP4:fps:delegate: with default fps value 25, and no delegate.

 @param filePath <#filePath description#>
 */
- (void)playHWDMp4:(NSString *)filePath;


/**
 begin decoding and palying a MP4 file, will do nothing if filePath is not a valid value

 @param filePath MP4's path
 @param fps frames per second, determine each frame's duration, value must be in range [0,60], otherwise would be set to nearest valid value.
 @param delegate <#delegate description#>
 */
- (void)playHWDMP4:(NSString *)filePath fps:(NSInteger)fps delegate:(id<HWDMP4PlayDelegate>)delegate;


/**
 begin decoding and palying a MP4 file, will do nothing if filePath is not a valid value
 
 @param filePath MP4's path
 @param fps frames per second, determine each frame's duration, value must be in range [0,60], otherwise would be set to nearest valid value.
 @param mode determine the texture blendmode default is QGHWDTextureBlendMode_AlphaLeft
 @param delegate <#delegate description#>
 */
- (void)playHWDMP4:(NSString *)filePath fps:(NSInteger)fps blendMode:(QGHWDTextureBlendMode)mode delegate:(id<HWDMP4PlayDelegate>)delegate;

- (void)playHWDMP4:(NSString *)filePath fps:(NSInteger)fps blendMode:(QGHWDTextureBlendMode)mode delegate:(id<HWDMP4PlayDelegate>)delegate attachments:(QGAdvancedGiftAttachmentsConfigModel*)attachment;

/**
 stop the playing and decoding peocess, and abandon contexts.
 */
- (void)stopHWDMP4;


/**
 pause playing frames, keep contexts.
 */
- (void)pauseHWDMP4;


/**
 resume from pause status, would not work when the decoding&diplaying process are stoped or finish.
 */
- (void)resumeHWDMP4;

@end
