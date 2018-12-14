//
//  UIView+MP4HWDecode.m
//  QGame
//
//  Created by Chanceguo on 17/2/28.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+MP4HWDecode.h"
#import "QGAnimatedImageDecodeManager.h"
#import "QGMP4HWDFileInfo.h"
#import "QGMP4FrameHWDecoder.h"
#import "QGBaseAnimatedImageFrame+Displaying.h"
#import <objc/runtime.h>
#import "QGHWDMP4OpenGLView.h"
#import "QGWeakProxy.h"
#import "NSNotificationCenter+ThreadSafe.h"
#import "QGHWDMP4OpenGLView.h"
#import "QGMP4FrameHWDecoder.h"
#import "QGMP4AnimatedImageFrame.h"
#import "MetalTest-Swift.h"

NSInteger const QGMP4HWDDefaultFPS = 18;
NSInteger const QGMP4HWDMinFPS = 1;
NSInteger const QGMP4HWDMaxFPS = 60;

@interface UIView () <QGAnimatedImageDecoderDelegate,QGHWDMP4OpenGLViewDelegate>

@property (nonatomic, strong) QGMP4AnimatedImageFrame *currentHWDFrameInstance; //store the frame value

//MP4文件信息
@property (nonatomic, strong) QGMP4HWDFileInfo *fileInfo;

//vsync刷新
@property (nonatomic, strong) CADisplayLink *displayLink;

//解码模块
@property (nonatomic, strong) QGAnimatedImageDecodeManager *decodeManager;

@property (nonatomic, strong) QGAnimatedImageDecodeConfig *decodeConfig;

//delegate 回调
@property (nonatomic, strong) NSOperationQueue *callbackQueue;

//标记是否暂停中
@property (nonatomic, assign) BOOL onPause;

//opengl绘制图层
@property (nonatomic, strong) QGHWDMP4OpenGLView *HWDOpenGLView;

@property (nonatomic, strong) QGHWDMetalView *HWDMetalView;

//标记是否结束
@property (nonatomic, assign) BOOL isFinish;

@end

@implementation UIView (MP4HWDecode)

#pragma mark - private

- (void)registerNotification {

    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveEnterBackgroundNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveWillEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveEnterBackgroundNotification:(NSNotification *)notification {

    //QG_Event(MODULE_DECODE, @"didReceiveEnterBackgroundNotification");
    [self stopHWDMP4];
}

- (void)didReceiveWillEnterForegroundNotification:(NSNotification *)notification {

    //QG_Event(MODULE_DECODE, @"didReceiveWillEnterForegroundNotification");
    [self resumeHWDMP4];
}

#pragma mark - main

- (void)playHWDMp4:(NSString *)filePath {
    [self playHWDMP4:filePath fps:QGMP4HWDDefaultFPS delegate:nil];
}

- (void)playHWDMP4:(NSString *)filePath fps:(NSInteger)fps delegate:(id<HWDMP4PlayDelegate>)delegate {
    [self playHWDMP4:filePath fps:fps blendMode:QGHWDTextureBlendMode_AlphaLeft delegate:delegate];
}

- (void)playHWDMP4:(NSString *)filePath fps:(NSInteger)fps blendMode:(QGHWDTextureBlendMode)mode delegate:(id<HWDMP4PlayDelegate>)delegate {
    
    //QG_Info(MODULE_DECODE, @"playHWDMP4:%@ fps:%@",filePath,@(fps));
    
    NSAssert([NSThread isMainThread], @"HWDMP4 needs to be accessed on the main thread.");
    
    //filePath check
    if (!filePath || filePath.length == 0) {
        //QG_Event(MODULE_DECODE, @"has no filePath!");
        return ;
    }
    
    @synchronized (self) {
        self.isFinish = NO;
    }
    
    self.fileInfo = [[QGMP4HWDFileInfo alloc] init];
    self.fileInfo.filePath = filePath;
    
    self.HWDFps = fps;
    
    //callback
    self.MP4PlayDelegate = delegate;
    if (self.MP4PlayDelegate && !self.callbackQueue) {
        //QG_Info(MODULE_DECODE, @"init callback queue");
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        self.callbackQueue = queue;
    }
    
    //reset
    self.currentHWDFrameInstance = nil;
    self.decodeManager = nil;
    self.onPause = NO;
    [self.displayLink invalidate];
    
    if (!self.decodeConfig) {
        QGAnimatedImageDecodeConfig *config = [[QGAnimatedImageDecodeConfig alloc] init];
        config.threadCount = 1;
        config.bufferCount = 1;
        self.decodeConfig = config;
        //QG_Info(MODULE_DECODE, @"init decode config threadCount:%@ bufferCount:%@",@(self.decodeConfig.threadCount),@(self.decodeConfig.bufferCount));
    }
    
    if (!self.HWDOpenGLView) {
        QGHWDMP4OpenGLView *openGLView = [[QGHWDMP4OpenGLView alloc] initWithFrame:self.bounds];
        openGLView.displayDelegate = self;
        [self addSubview:openGLView];
        openGLView.userInteractionEnabled = NO;
        [openGLView setupGL];
        self.HWDOpenGLView = openGLView;
        [self registerNotification];
        //QG_Info(MODULE_DECODE, @"init HWDOpenGLView");
    }
    
    if (!self.HWDMetalView) {
        QGHWDMetalView *metalView = [[QGHWDMetalView alloc] initWithFrame:self.bounds];
        [self addSubview:metalView];
        self.HWDMetalView = metalView;
    }
    
    self.HWDOpenGLView.blendMode = mode;
    
    self.decodeManager = [[QGAnimatedImageDecodeManager alloc] initWith:self.fileInfo config:self.decodeConfig delegate:self];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

//check each VSync
- (void)step {

    if (self.onPause) {
        return ;
    }
    
    NSInteger nextIndex = self.currentHWDFrame.frameIndex + 1;
    if (!self.currentHWDFrame) {
        nextIndex = 0;
    }
    
    if (nextIndex == 0 || [self.currentHWDFrameInstance shouldFinishDisplaying]) {
        QGMP4AnimatedImageFrame *nextFrame = (QGMP4AnimatedImageFrame *)[self.decodeManager consumeDecodedFrame:nextIndex];
        if (nextFrame && nextFrame.frameIndex == nextIndex && [nextFrame isKindOfClass:[QGMP4AnimatedImageFrame class]]) {
            nextFrame.startDate = [NSDate date];
            
            //fps策略：优先使用调用者指定的fps；若不合法则使用mp4中的数据；若还是不合法则使用默认18
            NSInteger fps = self.HWDFps;
            if (fps < QGMP4HWDMinFPS || fps > QGMP4HWDMaxFPS) {
                if (nextFrame.defaultFps >= QGMP4HWDMinFPS && nextFrame.defaultFps <= QGMP4HWDMaxFPS) {
                    fps = nextFrame.defaultFps;
                }else {
                    fps = QGMP4HWDDefaultFPS;
                }
            }
            nextFrame.duration = 1000/(double)fps;
            //QG_Debug(MODULE_DECODE, @"display frame:%@, has frameBuffer:%@",@(nextIndex),@(nextFrame.pixelBuffer != nil));
//            [self.HWDOpenGLView displayPixelBuffer:nextFrame.pixelBuffer];
            [self.HWDMetalView displayWithPixelBuffer:nextFrame.pixelBuffer];
//            [self.HWDMetalView displayWithImageName:@"31"];
            self.currentHWDFrameInstance = nextFrame;
            
            [self.callbackQueue addOperationWithBlock:^{
                if ([self.MP4PlayDelegate respondsToSelector:@selector(viewDidPlayMP4AtFrame:view:)]) {
                    [self.MP4PlayDelegate viewDidPlayMP4AtFrame:self.currentHWDFrame view:self];
                }
            }];
        }
    }
}

- (void)stopHWDMP4 {
    
    //QG_Info(MODULE_DECODE, @"stopHWDMP4");
    @synchronized (self) {
        if (self.isFinish) {
            //QG_Info(MODULE_DECODE, @"isFinish already set");
            return ;
        }
        self.isFinish = YES;
    }
    
    self.onPause = YES;
    self.HWDOpenGLView.pause = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [self.callbackQueue addOperationWithBlock:^{
        if ([self.MP4PlayDelegate respondsToSelector:@selector(viewDidStopPlayMP4:view:)]) {
            [self.MP4PlayDelegate viewDidStopPlayMP4:self.currentHWDFrame.frameIndex view:self];
        }
        if ([self.MP4PlayDelegate respondsToSelector:@selector(viewDidFinishPlayMP4:view:)]) {
            [self.MP4PlayDelegate viewDidFinishPlayMP4:self.currentHWDFrame.frameIndex+1 view:self];
        }
    }];
    
    self.decodeManager = nil;
    self.decodeConfig = nil;
    self.currentHWDFrameInstance = nil;
    self.fileInfo = nil;
}

- (void)pauseHWDMP4 {
    
    //QG_Info(MODULE_DECODE, @"pauseHWDMP4");
    self.onPause = YES;
    self.HWDOpenGLView.pause = YES;
    self.displayLink.paused = YES;
    
    [self.callbackQueue addOperationWithBlock:^{
        if ([self.MP4PlayDelegate respondsToSelector:@selector(viewDidStopPlayMP4:view:)]) {
            [self.MP4PlayDelegate viewDidStopPlayMP4:self.currentHWDFrame.frameIndex view:self];
        }
    }];
}

- (void)resumeHWDMP4 {
    
    //QG_Info(MODULE_DECODE, @"resumeHWDMP4");
    self.onPause = NO;
    self.HWDOpenGLView.pause = NO;
    self.displayLink.paused = NO;
}

#pragma mark - delegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (Class)decoderClassForManager:(QGAnimatedImageDecodeManager *)manager {
    
    return [QGMP4FrameHWDecoder class];
}

- (void)decoderDidFinishDecode:(QGBaseDecoder *)decoder {
    
    //QG_Info(MODULE_DECODE, @"decoderDidFinishDecode.");
    [self stopHWDMP4];
}

- (void)decoderDidFailDecode:(QGBaseDecoder *)decoder error:(NSError *)error{

    //QG_Event(MODULE_DECODE, @"decoderDidFailDecode");
    [self stopHWDMP4];
    [self.callbackQueue addOperationWithBlock:^{
        if ([self.MP4PlayDelegate respondsToSelector:@selector(viewDidFailPlayMP4:)]) {
            [self.MP4PlayDelegate viewDidFailPlayMP4:error];
        }
    }];
}

- (void)onViewUnavailableStatus {
    
    //QG_Info(MODULE_DECODE, @"onViewUnavailableStatus");
    [self stopHWDMP4];
}

#pragma clang diagnostic pop

#pragma mark - setters&getters

- (QGMP4AnimatedImageFrame *)currentHWDFrame {
    return self.currentHWDFrameInstance;
}

- (void)setCurrentHWDFrameInstance:(QGMP4AnimatedImageFrame *)currentHWDFrameInstance {
    objc_setAssociatedObject(self, @"currentHWDFrameInstance", currentHWDFrameInstance, OBJC_ASSOCIATION_RETAIN);
}

- (QGMP4AnimatedImageFrame *)currentHWDFrameInstance {
    return objc_getAssociatedObject(self, @"currentHWDFrameInstance");
}

- (id<HWDMP4PlayDelegate>)MP4PlayDelegate {
    return objc_getAssociatedObject(self, @"MP4PlayDelegate");
}

- (void)setMP4PlayDelegate:(id<HWDMP4PlayDelegate>)MP4PlayDelegate {
    id weakDelegate = [QGWeakProxy proxyWithTarget:MP4PlayDelegate];
    return objc_setAssociatedObject(self, @"MP4PlayDelegate", weakDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)MP4FilePath {
    return objc_getAssociatedObject(self, @"MP4FilePath");
}

- (void)setMP4FilePath:(NSString *)MP4FilePath {
    objc_setAssociatedObject(self, @"MP4FilePath", MP4FilePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)HWDFps {
    return [objc_getAssociatedObject(self, @"HWDFps") integerValue];
}

- (void)setHWDFps:(NSInteger)HWDFps {
    objc_setAssociatedObject(self, @"HWDFps", @(HWDFps), OBJC_ASSOCIATION_RETAIN);
}

- (void)setDisplayLink:(CADisplayLink *)displayLink {
    objc_setAssociatedObject(self, @"displayLink", displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CADisplayLink *)displayLink {
    return objc_getAssociatedObject(self, @"displayLink");
}

- (void)setDecodeManager:(QGAnimatedImageDecodeManager *)decodeManager {
    objc_setAssociatedObject(self, @"decodeManager", decodeManager, OBJC_ASSOCIATION_RETAIN);
}

- (QGAnimatedImageDecodeManager *)decodeManager {
    return objc_getAssociatedObject(self, @"decodeManager");
}

- (void)setFileInfo:(QGMP4HWDFileInfo *)fileInfo {
    objc_setAssociatedObject(self, @"fileInfo", fileInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (QGMP4HWDFileInfo *)fileInfo {
    return objc_getAssociatedObject(self, @"fileInfo");
}

- (QGAnimatedImageDecodeConfig *)decodeConfig {
    return objc_getAssociatedObject(self, @"decodeConfig");
}

- (void)setDecodeConfig:(QGAnimatedImageDecodeConfig *)decodeConfig {
    objc_setAssociatedObject(self, @"decodeConfig", decodeConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCallbackQueue:(NSOperationQueue *)callbackQueue {
    objc_setAssociatedObject(self, @"callbackQueue", callbackQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSOperationQueue *)callbackQueue {
    return objc_getAssociatedObject(self, @"callbackQueue");
}

- (void)setHWDOpenGLView:(QGHWDMP4OpenGLView *)HWDOpenGLView {
    objc_setAssociatedObject(self, @"HWDOpenGLView", HWDOpenGLView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (QGHWDMP4OpenGLView *)HWDOpenGLView {
    return objc_getAssociatedObject(self, @"HWDOpenGLView");
}

- (void)setHWDMetalView:(QGHWDMetalView *)HWDMetalView {
    objc_setAssociatedObject(self, @"HWDMetalView", HWDMetalView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (QGHWDMetalView *)HWDMetalView {
    return objc_getAssociatedObject(self, @"HWDMetalView");
}

- (void)setOnPause:(BOOL)onPause {
    objc_setAssociatedObject(self, @"onPause", @(onPause), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)onPause {
    return [objc_getAssociatedObject(self, @"onPause") boolValue];
}

- (void)setIsFinish:(BOOL)isFinish {
    objc_setAssociatedObject(self, @"isFinish", @(isFinish), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isFinish {
    return [objc_getAssociatedObject(self, @"isFinish") boolValue];
}

@end
