//
//  QGMP4Parser.h
//  QGMP4Parser
//
//  Created by Chanceguo on 2017/4/11.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, QGMP4BoxType) {
    
    QGMP4BoxType_unknown        =   0x0,
    QGMP4BoxType_ftyp           =   0x66747970,
    QGMP4BoxType_free           =   0x66726565,
    QGMP4BoxType_mdat           =   0x6d646174,
    QGMP4BoxType_moov           =   0x6d6f6f76,
    QGMP4BoxType_mvhd           =   0x6d766864,
    QGMP4BoxType_iods           =   0x696f6473,
    QGMP4BoxType_trak           =   0x7472616b,
    QGMP4BoxType_tkhd           =   0x746b6864,
    QGMP4BoxType_edts           =   0x65647473,
    QGMP4BoxType_elst           =   0x656c7374,
    QGMP4BoxType_mdia           =   0x6d646961,
    QGMP4BoxType_mdhd           =   0x6d646864,
    QGMP4BoxType_hdlr           =   0x68646c72,
    QGMP4BoxType_minf           =   0x6d696e66,
    QGMP4BoxType_vmhd           =   0x766d6864,
    QGMP4BoxType_dinf           =   0x64696e66,
    QGMP4BoxType_dref           =   0x64726566,
    QGMP4BoxType_url            =   0x75726c,
    QGMP4BoxType_stbl           =   0x7374626c,
    QGMP4BoxType_stsd           =   0x73747364,
    QGMP4BoxType_avc1           =   0x61766331,
    QGMP4BoxType_avcC           =   0x61766343,
    QGMP4BoxType_stts           =   0x73747473,
    QGMP4BoxType_stss           =   0x73747373,
    QGMP4BoxType_stsc           =   0x73747363,
    QGMP4BoxType_stsz           =   0x7374737a,
    QGMP4BoxType_stco           =   0x7374636f,
    QGMP4BoxType_udta           =   0x75647461,
    QGMP4BoxType_meta           =   0x6d657461,
    QGMP4BoxType_ilst           =   0x696c7374,
    QGMP4BoxType_data           =   0x64617461,
    QGMP4BoxType_wide           =   0x77696465,
    QGMP4BoxType_loci           =   0x6c6f6369,
    QGMP4BoxType_smhd           =   0x736d6864,
};

@class QGMP4Box;
@class QGMP4Parser;
@protocol QGMP4ParserDelegate <NSObject>

- (void)didParseMP4Box:(QGMP4Box *)box parser:(QGMP4Parser *)parser;

- (void)MP4FileDidFinishParse:(QGMP4Parser *)parser;

@end

@interface QGMP4Box : NSObject

@property (nonatomic, assign) QGMP4BoxType type;

@property (nonatomic, assign) unsigned long long length;

@property (nonatomic, assign) unsigned long long startIndexInBytes;

@property (nonatomic, weak) QGMP4Box *superBox;

@property (nonatomic, strong) NSMutableArray *subBoxes;

- (instancetype)initWithType:(QGMP4BoxType)boxType;

@end

@interface QGMP4MdatBox : QGMP4Box

@end

@interface QGMP4AvccBox : QGMP4Box

@end

@interface QGMP4MvhdBox : QGMP4Box

@end

//sample description
@interface QGMP4StsdBox : QGMP4Box

@end

//sample size
@interface QGMP4StszBox : QGMP4Box

@end

@interface QGMP4BoxFactory : NSObject

+ (QGMP4Box *)createBoxForType:(QGMP4BoxType)type;

@end

@interface QGMP4Parser : NSObject

@property (nonatomic, strong) QGMP4Box *rootBox;

@property (nonatomic, weak) id<QGMP4ParserDelegate> delegate;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)parse;

- (NSData *)readDataForBox:(QGMP4Box *)box;

@end

@interface QGMP4ParserProxy : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;

@property (nonatomic, assign) NSInteger picWidth;

@property (nonatomic, assign) NSInteger picHeight;

@property (nonatomic, assign) NSInteger fps;

@property (nonatomic, assign) double duration;

@property (nonatomic, strong) NSData *spsData;

@property (nonatomic, strong) NSData *ppsData;

@property (nonatomic, strong) NSArray *packtSizes;

@property (nonatomic, strong) QGMP4Box *rootBox;

@property (nonatomic, strong) QGMP4MdatBox *mdatBox;

@property (nonatomic, strong) QGMP4AvccBox *avccBox;

@property (nonatomic, strong) QGMP4StszBox *stszBox;    //size

@property (nonatomic, strong) QGMP4StsdBox *stsdBox;    //sample description

@property (nonatomic, strong) QGMP4MvhdBox *mvhdBox;

- (void)parse;

- (NSData *)readNextPacket;

@end
