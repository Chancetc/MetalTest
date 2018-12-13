//
//  QGMP4FrameHWDecoder.m
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGMP4FrameHWDecoder.h"
#import "QGWeakProxy.h"
#import "QGMP4AnimatedImageFrame.h"
#import "QGBaseAnimatedImageFrame+Displaying.h"
#import <VideoToolbox/VideoToolbox.h>
#import "QGHWDMP4OpenGLView.h"
#import "QGMP4Parser.h"
#import "QGSafeMutableArray.h"
#import "NSNotificationCenter+ThreadSafe.h"
#include <sys/sysctl.h>

@interface UIDevice (HWD)

- (BOOL)isSimulator;

@end

@implementation UIDevice (HWD)

- (BOOL)isSimulator {
    static dispatch_once_t one;
    static BOOL simu = NO;
    dispatch_once(&one, ^{
        NSString *model = [self machineModel];
        if ([model isEqualToString:@"x86_64"] || [model isEqualToString:@"i386"]) {
            simu = YES;
        }
    });
    return simu;
}

- (NSString *)machineModel {
    static dispatch_once_t one;
    static NSString *model;
    dispatch_once(&one, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

@end

@interface NSArray (SafeOperation)

@end

@implementation NSArray (SafeOperation)

- (id)safeObjectAtIndex:(NSUInteger)index
{
    if (index >= self.count) {
        NSAssert(0, @"Error: access to array index which is beyond bounds! ");
        return nil;
    }
    
    return self[index];
}

@end

@interface QGMP4FrameHWDecoder() {
    
    NSMutableArray *_buffers;
    
    int _videoStream;
    int _outputWidth, _outputHeight;
    OSStatus _status;
    BOOL _isFinish;
    VTDecompressionSessionRef _mDecodeSession;
    CMFormatDescriptionRef  _mFormatDescription;
    NSInteger _finishFrameIndex;
    NSError *_constructErr;
    QGMP4ParserProxy *_mp4Parser;
    
}

@property (nonatomic, strong) NSData *ppsData; //Picture Parameter Set
@property (nonatomic, strong) NSData *spsData; //Sequence Parameter Set

@end

NSString *const QGMP4HWDErrorDomain = @"QGMP4HWDErrorDomain";

@implementation QGMP4FrameHWDecoder


+ (NSString *)errorDescriptionForCode:(QGMP4HWDErrorCode)errorCode {
    
    NSArray *errorDescs = @[@"文件不存在",@"非法文件格式",@"无法获取视频流信息",@"无法获取视频流",@"VTB创建desc失败",@"VTB创建session失败"];
    NSString *desc = @"";
    switch (errorCode) {
        case QGMP4HWDErrorCode_FileNotExist:
            desc = [errorDescs safeObjectAtIndex:0];
            break;
        case QGMP4HWDErrorCode_InvalidMP4File:
            desc = [errorDescs safeObjectAtIndex:1];
            break;
        case QGMP4HWDErrorCode_CanNotGetStreamInfo:
            desc = [errorDescs safeObjectAtIndex:2];
            break;
        case QGMP4HWDErrorCode_CanNotGetStream:
            desc = [errorDescs safeObjectAtIndex:3];
            break;
        case QGMP4HWDErrorCode_ErrorCreateVTBDesc:
            desc = [errorDescs safeObjectAtIndex:4];
            break;
        case QGMP4HWDErrorCode_ErrorCreateVTBSession:
            desc = [errorDescs safeObjectAtIndex:5];
            break;
            
        default:
            break;
    }
    return desc;
}

- (instancetype)initWith:(QGMP4HWDFileInfo *)fileInfo error:(NSError *__autoreleasing *)error{
    
    if (self = [super initWith:fileInfo error:error]) {
        BOOL isOpenSuccess = [self onInputStart];
        if (!isOpenSuccess) {
            //QG_Event(MODULE_DECODE, @"onInputStart fail!");
            *error = _constructErr;
            self = nil;
            return nil;
        }
        [self registerNotification];
    }
    return self;
}

- (void)registerNotification {
    
    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addSafeObserver:self selector:@selector(didReceiveEnterBackgroundNotification:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)didReceiveEnterBackgroundNotification:(NSNotification *)notification {
    
    [self onInputEnd];
}

- (void)decodeFrame:(NSInteger)frameIndex buffers:(NSMutableArray *)buffers {
    
    if (frameIndex == self.currentDecodeFrame) {
        //QG_Info(MODULE_DECODE, @"already in decode");
        return ;
    }
    self.currentDecodeFrame = frameIndex;
    _buffers = buffers;
    if ([UIDevice currentDevice].isSimulator) {
        NSLog(@"whould not decode in simulator");
//        return ;
    }
    [[QGWeakProxy proxyWithTarget:self] performSelector:@selector(_decodeFrame:) onThread:self.decodeThread withObject:@(frameIndex) waitUntilDone:NO];
}

- (void)_decodeFrame:(NSNumber *)frameIndexNum {
    
    NSInteger frameIndex = [frameIndexNum integerValue];
    if (!_buffers || _buffers.count == 0) {
        //QG_Event(MODULE_DECODE, @"_buffers is nil:%@",_buffers);
        return ;
    }
    
    if (_isFinish) {
        //QG_Event(MODULE_DECODE, @"current file stream is to end.");
        return ;
    }
    
    if (self.spsData == nil || self.ppsData == nil) {
        //QG_Event(MODULE_DECODE, @"spsData or ppsData is nil!");
        return ;
    }
    
    //解码开始时间
    NSDate *startDate = [NSDate date];
    NSData *packetData = [_mp4Parser readNextPacket];
    if (!packetData) {
        _finishFrameIndex = frameIndex;
        [self onInputEnd];
        return;
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    // 4. get NALUnit payload into a CMBlockBuffer,
    CMBlockBufferRef blockBuffer = NULL;
    
    _status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                 (void *)packetData.bytes,
                                                 packetData.length,
                                                 kCFAllocatorNull, NULL, 0,
                                                 packetData.length, 0,
                                                 &blockBuffer);
    //QG_Debug(MODULE_DECODE,@"BlockBufferCreation: %@", (_status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
    
    // 6. create a CMSampleBuffer.
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {packetData.length};
    _status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                        blockBuffer,
                                        _mFormatDescription,
                                        1, 0, NULL, 1, sampleSizeArray,
                                        &sampleBuffer);
    
    // 7. use VTDecompressionSessionDecodeFrame
    VTDecodeFrameFlags flags = 0;
    VTDecodeInfoFlags flagOut = 0;
    _status = VTDecompressionSessionDecodeFrame(_mDecodeSession,
                                                sampleBuffer,
                                                flags,
                                                &outputPixelBuffer,
                                                &flagOut);
    
    if(_status == kVTInvalidSessionErr) {
        //QG_Event(MODULE_DECODE,@"IOS8VT: Invalid session, reset decoder session");
    } else if(_status == kVTVideoDecoderBadDataErr) {
        //QG_Event(MODULE_DECODE,@"IOS8VT: decode failed status=%@(Bad data)", @(_status));
    } else if(_status != noErr) {
        //QG_Event(MODULE_DECODE,@"IOS8VT: decode failed status=%@", @(_status));
    }
    CFRelease(sampleBuffer);
    if (blockBuffer) {
        CFRelease(blockBuffer);
    }
    
    QGMP4AnimatedImageFrame *newFrame = [[QGMP4AnimatedImageFrame alloc] init];
    // imagebuffer会在frame回收时释放
    newFrame.pixelBuffer = outputPixelBuffer;
    newFrame.frameIndex = frameIndex;
    NSTimeInterval decodeTime = [[NSDate date] timeIntervalSinceDate:startDate]*1000;
    newFrame.decodeTime = decodeTime;
    newFrame.defaultFps = (int)_mp4Parser.fps;
    
    //8. insert into buffer
    NSInteger index = frameIndex%_buffers.count;
    _buffers[index] = newFrame;
    
}

#pragma mark - override

- (BOOL)shouldStopDecode:(NSInteger)nextFrameIndex {
    
    return _isFinish;
}

- (BOOL)isFrameIndexBeyondEnd:(NSInteger)frameIndex {
    
    if (_finishFrameIndex > 0) {
        return (frameIndex >= _finishFrameIndex);
    }
    return NO;
}

-(void)dealloc {
    
    //QG_Info(MODULE_DECODE, @"decoder dealloc");
    [self onInputEnd];
    self.decodeThread.occupied = NO;
    self.fileInfo.occupiedCount --;
    if (self.fileInfo.occupiedCount <= 0) {
        
    }
}

#pragma mark - private methods

- (BOOL)onInputStart {
    
    //QG_Info(MODULE_DECODE, @"onInputStart");
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:self.fileInfo.filePath]) {
        //QG_Event(MODULE_DECODE, @"error! file not exists at:%@",self.fileInfo.filePath);
        //        NSAssert(0, @"file not exists at:%@",self.fileInfo.filePath);
        _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_FileNotExist userInfo:nil];
        return NO;
    }
    _mp4Parser = [[QGMP4ParserProxy alloc] initWithFilePath:self.fileInfo.filePath];
    [_mp4Parser parse];
    
    _isFinish = NO;
    self.spsData = nil;
    self.ppsData = nil;
    //
    //    //注册所有format和codecs
    //    avcodec_register_all();
    //    av_register_all();
    
    //打开文件
    //    _pFormatCtx = NULL;
    //    if (avformat_open_input(&_pFormatCtx,[self.fileInfo.filePath cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL) != 0) {
    //        //QG_Event(MODULE_DECODE,@"Couldn't open file:%@",self.fileInfo.filePath);
    //        _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_InvalidMP4File userInfo:nil];
    //        return NO;
    //    }
    
    //    //获取视频流信息
    //    if (avformat_find_stream_info(_pFormatCtx, NULL) < 0) {
    //        //QG_Event(MODULE_DECODE,@"Couldn't find stream information");
    //        NSAssert(0, @"Couldn't find stream information");
    //        _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_CanNotGetStreamInfo userInfo:nil];
    //        return NO;
    //    }
    
    //    //获取第一个视频流
    //    if ((_videoStream = av_find_best_stream(_pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0)) < 0) {
    //        //QG_Event(MODULE_DECODE,@"Cannot find a video stream in the input file\n");
    //        _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_CanNotGetStream userInfo:nil];
    //        return NO;
    //    }
    
    //获取视频流的codec context
    //    self.pCodecCtx = self.pFormatCtx->streams[_videoStream]->codec;
    
    _outputWidth = (int)_mp4Parser.picWidth;
    _outputHeight = (int)_mp4Parser.picHeight;
    
    BOOL paramsSetInitSuccess = [self initPPSnSPS];
    return paramsSetInitSuccess;
}

- (BOOL)initPPSnSPS {
    
    //QG_Info(MODULE_DECODE, @"initPPSnSPS");
    if (self.spsData && self.ppsData) {
        //QG_Event(MODULE_DECODE, @"sps&pps is already has value.");
        return YES;
    }
    // 1. get SPS,PPS form stream data, and create CMFormatDescription 和 VTDecompressionSession
    //    uint8_t *data = self.pCodecCtx -> extradata;
    //    int size = self.pCodecCtx -> extradata_size;
    //
    //    int startCodeSPSIndex = 0;
    //    int startCodePPSIndex = 0;
    //    int spsLength = 0;
    //    int ppsLength = 0;
    //
    //    NSString *tmp3 = [NSString new];
    //    for(int i = 0; i < size; i++) {
    //        NSString *str = [NSString stringWithFormat:@" %.2X",data[i]];
    //        tmp3 = [tmp3 stringByAppendingString:str];
    //        switch (data[i]) {
    //            case 0x67:
    //                startCodeSPSIndex = i;
    //                break;
    //            case 0x68:
    //                startCodePPSIndex = i;
    //                break;
    //            default:
    //                break;
    //        }
    //    }
    //    //QG_Info(MODULE_DECODE, @"avcc extra data is :%@",tmp3);
    //    spsLength = data[startCodeSPSIndex-1];
    //    ppsLength = data[startCodePPSIndex-1];
    //    //QG_Info(MODULE_DECODE, @"startCodeSPSIndex:%@ startCodePPSIndex:%@ spsLength:%@ ppsLength:%@",@(startCodeSPSIndex),@(startCodePPSIndex),@(spsLength),@(ppsLength));
    //
    //    int nalu_type = ((uint8_t) data[startCodeSPSIndex] & 0x1F);
    //    if (nalu_type == 7) {
    //        //QG_Info(MODULE_DECODE, @"spsData init");
    //        self.spsData = [NSData dataWithBytes:&(data[startCodeSPSIndex]) length: spsLength];
    //    }
    //
    //    nalu_type = ((uint8_t) data[startCodePPSIndex] & 0x1F);
    //    if (nalu_type == 8) {
    //        //QG_Info(MODULE_DECODE, @"ppsdata init");
    //        self.ppsData = [NSData dataWithBytes:&(data[startCodePPSIndex]) length: ppsLength];
    //    }
    
    self.spsData = _mp4Parser.spsData;
    self.ppsData = _mp4Parser.ppsData;
    
    // 2. create  CMFormatDescription
    if (self.spsData != nil && self.ppsData != nil) {
        const uint8_t* const parameterSetPointers[2] = { (const uint8_t*)[self.spsData bytes], (const uint8_t*)[self.ppsData bytes] };
        const size_t parameterSetSizes[2] = { [self.spsData length], [self.ppsData length] };
        _status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_mFormatDescription);
        if (_status != noErr) {
            //QG_Event(MODULE_DECODE,@"CMVideoFormatDescription. Creation: %@.", (_status == noErr) ? @"successfully." : @"failed.");
            _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_ErrorCreateVTBDesc userInfo:nil];
            return NO;
        }
    }
    
    // 3. create VTDecompressionSession
    CFDictionaryRef attrs = NULL;
    const void *keys[] = {kCVPixelBufferPixelFormatTypeKey};
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    
    _status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                           _mFormatDescription,
                                           NULL, attrs,
                                           &callBackRecord,
                                           &_mDecodeSession);
    if (_status != noErr) {
        //QG_Event(MODULE_DECODE, @"error!create mDecodeSession fail!");
        CFRelease(attrs);
        _constructErr = [NSError errorWithDomain:QGMP4HWDErrorDomain code:QGMP4HWDErrorCode_ErrorCreateVTBSession userInfo:nil];
        return NO;
    }
    CFRelease(attrs);
    return YES;
}

- (void)onInputEnd {
    
    //QG_Info(MODULE_DECODE, @"onInputEnd");
    @synchronized (self) {
        if (_isFinish) {
            //QG_Info(MODULE_DECODE, @"already ended.");
            return ;
        }
        if (_mDecodeSession) {
            VTDecompressionSessionInvalidate(_mDecodeSession);
            _mDecodeSession = nil;
        }
        if (self.spsData || self.ppsData) {
            self.spsData = nil;
            self.ppsData = nil;
        }
        
        //        // Free the packet that was allocated by av_read_frame
        //        av_packet_unref(&_packet);
        //
        //        // Close the codec
        //        if (self.pCodecCtx) {
        //            avcodec_close(self.pCodecCtx);
        //        }
        //
        //        // Close the video file
        //        if (self.pFormatCtx) {
        //            avformat_close_input(&_pFormatCtx);
        //            avformat_free_context(self.pFormatCtx);
        //        }
        
        _isFinish = YES;
    }
}

//decode callback
void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@end
