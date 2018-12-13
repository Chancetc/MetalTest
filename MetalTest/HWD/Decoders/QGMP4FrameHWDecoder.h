//
//  QGMP4FrameHWDecoder.h
//  QGame
//
//  Created by Chanceguo on 2017/3/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGBaseDecoder.h"
#import "QGMP4HWDFileInfo.h"

/* 数字跳动的动画类型*/
typedef NS_ENUM(NSInteger, QGMP4HWDErrorCode){
    
    QGMP4HWDErrorCode_FileNotExist                  = 10000,          // 文件不存在
    QGMP4HWDErrorCode_InvalidMP4File                = 10001,          // 非法的mp4文件
    QGMP4HWDErrorCode_CanNotGetStreamInfo           = 10002,          // 无法获取视频流信息
    QGMP4HWDErrorCode_CanNotGetStream               = 10003,          // 无法获取视频流
    QGMP4HWDErrorCode_ErrorCreateVTBDesc            = 10004,          // 创建desc失败
    QGMP4HWDErrorCode_ErrorCreateVTBSession         = 10005,          // 创建session失败
};

@interface QGMP4FrameHWDecoder : QGBaseDecoder


+ (NSString *)errorDescriptionForCode:(QGMP4HWDErrorCode)errorCode;

@end
