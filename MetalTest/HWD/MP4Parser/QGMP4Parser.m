//
//  QGMP4Parser.m
//  QGMP4Parser
//
//  Created by Chanceguo on 2017/4/11.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGMP4Parser.h"

static NSInteger kQGBoxSizeLengthInBytes = 4;
static NSInteger kQGBoxTypeLengthInBytes = 4;

#pragma mark - boxes
#pragma mark -- base box
@implementation QGMP4Box

- (instancetype)initWithType:(QGMP4BoxType)boxType {
    
    if (self = [super init]) {
        _type = boxType;
    }
    return self;
}

- (NSString *)description {
    
    return [self descriptionForRecursionLevel:0];
}

- (NSString *)descriptionForRecursionLevel:(NSInteger)level {
    
    __block NSString *des = [NSString stringWithFormat:@"Box:%@ offset:%@ size:%@ ",self.typeString,@(self.startIndexInBytes),@(self.length)];
    for (int i = 0; i < level; i++) {
        des = [NSString stringWithFormat:@"|--%@",des];
    }
    des = [NSString stringWithFormat:@"\n%@",des];
    [self.subBoxes enumerateObjectsUsingBlock:^(QGMP4Box *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        des = [des stringByAppendingString:[obj descriptionForRecursionLevel:(level+1)]];
    }];
    return des;
}

- (NSString *)typeString {
    
    NSUInteger value = self.type;
    NSString *des = @"";
    while (value > 0) {
        NSUInteger hexValue = value&0xff;
        value = value>>8;
        des = [NSString stringWithFormat:@"%c%@",(int)hexValue,des];
    }
    return des;
}

@end

#pragma mark -- mdat box
@implementation QGMP4MdatBox


@end

#pragma mark -- avcc box
@implementation QGMP4AvccBox

@end

@implementation QGMP4MvhdBox


@end

@implementation QGMP4StsdBox


@end

@implementation QGMP4StszBox


@end

@implementation QGMP4BoxFactory

+ (QGMP4Box *)createBoxForType:(QGMP4BoxType)type {
    
    QGMP4Box *box = nil;
    switch (type) {
        case QGMP4BoxType_mdat:
            box = [[QGMP4MdatBox alloc] initWithType:type];
            break;
        case QGMP4BoxType_avcC:
            box = [[QGMP4AvccBox alloc] initWithType:type];
            break;
        case QGMP4BoxType_mvhd:
            box = [[QGMP4MvhdBox alloc] initWithType:type];
            break;
        case QGMP4BoxType_stsd:
            box = [[QGMP4StsdBox alloc] initWithType:type];
            break;
        case QGMP4BoxType_stsz:
            box = [[QGMP4StszBox alloc] initWithType:type];
            break;
        default:
            box = [[QGMP4Box alloc] initWithType:type];
            break;
    }
    return box;
}

@end

#pragma mark - mp4 parser
@interface QGMP4Parser()

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation QGMP4Parser

#pragma mark -- life cycle

- (instancetype)initWithFilePath:(NSString *)filePath {
    
    if (self = [super init]) {
        _filePath = filePath;
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:_filePath];
    }
    return self;
}

- (void)dealloc {
    
    [_fileHandle closeFile];
}

#pragma mark -- methods

- (void)parse {
    
    if (!_filePath || !_fileHandle) {
        return ;
    }
    
    unsigned long long fileSize = [_fileHandle seekToEndOfFile];
    [_fileHandle seekToFileOffset:0];
    NSData *data = [_fileHandle readDataOfLength:(NSUInteger)fileSize];
    const char *bytes = data.bytes;
    for (int i = 0; i < fileSize; i ++) {
        QGMP4BoxType type = [self checkBoxType:&bytes[i] length:fileSize-i];
        if (type != QGMP4BoxType_unknown) {
            
        }
    }
    
    _rootBox = [QGMP4BoxFactory createBoxForType:QGMP4BoxType_unknown];
    _rootBox.startIndexInBytes = 0;
    _rootBox.length = fileSize;
    NSMutableArray *BFSQueue = [NSMutableArray new];
    [BFSQueue addObject:_rootBox];
    
    QGMP4Box *calBox = _rootBox;
    
    //长度包含包含类型码长度+本身长度
    while ((calBox = [BFSQueue firstObject])) {
        [BFSQueue removeObjectAtIndex:0];
        
        if (calBox.length <= 2*(kQGBoxSizeLengthInBytes+kQGBoxTypeLengthInBytes)) {
            //长度限制
            continue ;
        }
        
        unsigned long long offset = 0;
        unsigned long long length = 0;
        QGMP4BoxType type = QGMP4BoxType_unknown;
        
        //第一个子box
        offset = calBox.superBox ? (calBox.startIndexInBytes + kQGBoxSizeLengthInBytes + kQGBoxTypeLengthInBytes) : 0;
        
        //avcbox
        if (calBox.type == QGMP4BoxType_avc1 || calBox.type == QGMP4BoxType_stsd) {
            unsigned long long avcOffset = calBox.startIndexInBytes+kQGBoxSizeLengthInBytes+kQGBoxTypeLengthInBytes;
            unsigned long long avcEdge = calBox.startIndexInBytes+calBox.length-kQGBoxSizeLengthInBytes-kQGBoxTypeLengthInBytes;
            unsigned long long avcLength = 0;
            QGMP4BoxType avcType = QGMP4BoxType_unknown;
            for (; avcOffset < avcEdge; avcOffset++) {
                readBoxTypeAndLength(_fileHandle, avcOffset, &avcType, &avcLength);
                if (avcType == QGMP4BoxType_avc1 || avcType == QGMP4BoxType_avcC) {
                    QGMP4Box *avcBox = [QGMP4BoxFactory createBoxForType:avcType];
                    avcBox.startIndexInBytes = avcOffset;
                    avcBox.length = avcLength;
                    if (!calBox.subBoxes) {
                        calBox.subBoxes = [NSMutableArray new];
                    }
                    [calBox.subBoxes addObject:avcBox];
                    avcBox.superBox = calBox;
                    [BFSQueue addObject:avcBox];
                    offset = (avcBox.startIndexInBytes+avcBox.length);
                    [self didParseBox:avcBox];
                    break ;
                }
            }
        }
        
        do {
            //判断是否会越界
            if ((offset+kQGBoxSizeLengthInBytes+kQGBoxTypeLengthInBytes)>(calBox.startIndexInBytes+calBox.length)) {
                break ;
            }
            readBoxTypeAndLength(_fileHandle, offset, &type, &length);
            
            if ((offset+length)>(calBox.startIndexInBytes+calBox.length)) {
                //reach to super box end or not a box
                break ;
            }
            
            if (![self isTypeValueValid:type] && (offset == (calBox.startIndexInBytes + kQGBoxSizeLengthInBytes + kQGBoxTypeLengthInBytes))) {
                //目前的策略是
                break ;
            }
            QGMP4Box *subBox = [QGMP4BoxFactory createBoxForType:type];
            subBox.startIndexInBytes = offset;
            subBox.length = length;
            subBox.superBox = calBox;
            if (!calBox.subBoxes) {
                calBox.subBoxes = [NSMutableArray new];
            }
            //加入box节点
            [calBox.subBoxes addObject:subBox];
            
            //进入广度优先遍历队列
            [BFSQueue addObject:subBox];
            [self didParseBox:subBox];
            
            //继续兄弟box
            offset += length;
        }while(1);
        
    }
    
    [self didFinisheParseFile];
    NSLog(@"%@",_rootBox);
}

- (NSData *)readDataForBox:(QGMP4Box *)box {
    
    if (!box) {
        return  nil;
    }
    [_fileHandle seekToFileOffset:box.startIndexInBytes];
    return [_fileHandle readDataOfLength:(NSUInteger)box.length];
}

#pragma mark -- private methods

- (void)didParseBox:(QGMP4Box *)box {
    
    if ([self.delegate respondsToSelector:@selector(didParseMP4Box:parser:)]) {
        [self.delegate didParseMP4Box:box parser:self];
    }
}

- (void)didFinisheParseFile {
    
    if ([self.delegate respondsToSelector:@selector(MP4FileDidFinishParse:)]) {
        [self.delegate MP4FileDidFinishParse:self];
    }
}


void readBoxTypeAndLength(NSFileHandle *fileHandle, unsigned long long offset, QGMP4BoxType *type, unsigned long long *length) {
    
    [fileHandle seekToFileOffset:offset];
    NSData *data = [fileHandle readDataOfLength:kQGBoxSizeLengthInBytes+kQGBoxTypeLengthInBytes];
    const char *bytes = data.bytes;
    *length = ((bytes[0]&0xff)<<24)+((bytes[1]&0xff)<<16)+((bytes[2]&0xff)<<8)+(bytes[3]&0xff);
    *type = ((bytes[4]&0xff)<<24)+((bytes[5]&0xff)<<16)+((bytes[6]&0xff)<<8)+(bytes[7]&0xff);
    if (*type == QGMP4BoxType_stsz) {
        
    }
}

- (QGMP4BoxType)checkBoxType:(const char *)data length:(unsigned long long)length{
    
    if (length < 4 || !data) {
        return QGMP4BoxType_unknown;
    }
    
    NSUInteger prefixValue = (data[0]<<24)+(data[1]<<16)+(data[2]<<8)+data[3];
    if ([self isTypeValueValid:prefixValue]) {
        return prefixValue;
    }
    return QGMP4BoxType_unknown;
}

- (BOOL)isTypeValueValid:(QGMP4BoxType)type {
    
    switch (type) {
        case QGMP4BoxType_ftyp:
        case QGMP4BoxType_free:
        case QGMP4BoxType_mdat:
        case QGMP4BoxType_moov:
        case QGMP4BoxType_mvhd:
        case QGMP4BoxType_trak:
        case QGMP4BoxType_tkhd:
        case QGMP4BoxType_edts:
        case QGMP4BoxType_elst:
        case QGMP4BoxType_mdia:
        case QGMP4BoxType_mdhd:
        case QGMP4BoxType_hdlr:
        case QGMP4BoxType_minf:
        case QGMP4BoxType_vmhd:
        case QGMP4BoxType_dinf:
        case QGMP4BoxType_dref:
        case QGMP4BoxType_url:
        case QGMP4BoxType_stbl:
        case QGMP4BoxType_stsd:
        case QGMP4BoxType_avc1:
        case QGMP4BoxType_avcC:
        case QGMP4BoxType_stts:
        case QGMP4BoxType_stss:
        case QGMP4BoxType_stsc:
        case QGMP4BoxType_stsz:
        case QGMP4BoxType_stco:
        case QGMP4BoxType_udta:
        case QGMP4BoxType_meta:
        case QGMP4BoxType_ilst:
        case QGMP4BoxType_data:
        case QGMP4BoxType_iods:
        case QGMP4BoxType_wide:
        case QGMP4BoxType_loci:
        case QGMP4BoxType_smhd:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

@end

#pragma mark - parser proxy

@interface QGMP4ParserProxy() <QGMP4ParserDelegate> {
    
    QGMP4Parser *_parser;
    NSInteger _currentPacketIndex;
}

@end

@implementation QGMP4ParserProxy

- (instancetype)initWithFilePath:(NSString *)filePath {
    
    if (self = [super init]) {
        
        _parser = [[QGMP4Parser alloc] initWithFilePath:filePath];
        _parser.delegate = self;
        _currentPacketIndex = -1;
    }
    return self;
}

- (NSInteger)picWidth {
    
    if (_picWidth == 0) {
        _picWidth = [self readPicWidth];
    }
    return _picWidth;
}

- (NSInteger)picHeight {
    
    if (_picHeight == 0) {
        _picHeight = [self readPicHeight];
    }
    return _picHeight;
}

- (NSInteger)fps {
    
    if (_fps == 0) {
        if (self.packtSizes.count == 0) {
            return 0;
        }
        _fps = self.packtSizes.count/self.duration;
    }
    return _fps;
}

- (double)duration {
    
    if (_duration == 0) {
        _duration = [self readDuration];
    }
    return _duration;
}

- (NSData *)spsData {
    
    if (!_spsData) {
        _spsData = [self readSPSData];
    }
    return _spsData;
}

- (NSData *)ppsData {
    
    if (!_ppsData) {
        _ppsData = [self readPPSData];
    }
    return _ppsData;
}

- (NSArray *)packtSizes {
    
    if (!_packtSizes) {
        [self readPacketSizeArr];
    }
    return _packtSizes;
}


- (void)parse {
    
    [_parser parse];
    _rootBox = _parser.rootBox;
}

- (NSData *)readSPSData {
    
    //boxsize(32)+boxtype(32)+prefix(40)+预留(3)+spsCount(5)+spssize(16)+...+ppscount(8)+ppssize(16)+...
    NSData *extraData = [_parser readDataForBox:_avccBox];
    if (extraData.length <= 8) {
        return nil;
    }
    const char *bytes = extraData.bytes;
    //sps数量 默认一个暂无使用
    //NSInteger spsCount = bytes[13]&0x1f;
    NSInteger spsLength = ((bytes[14]&0xff)<<8) + (bytes[15]&0xff);
    NSInteger naluType = (uint8_t)bytes[16]&0x1F;
    if (spsLength + 16 > extraData.length || naluType != 7) {
        return nil;
    }
    NSData *spsData = [NSData dataWithBytes:&bytes[16] length:spsLength];
    return spsData;
}

- (NSData *)readPPSData {
    
    NSData *extraData = [_parser readDataForBox:_avccBox];
    if (extraData.length <= 8) {
        return nil;
    }
    const char *bytes = extraData.bytes;
    NSInteger spsCount = bytes[13]&0x1f;
    NSInteger spsLength = ((bytes[14]&0xff)<<8) + (bytes[15]&0xff);
    NSInteger prefixLength = 16 + spsLength;
    
    while (--spsCount > 0) {
        
        if (prefixLength+2 >= extraData.length) {
            return nil;
        }
        NSInteger nextSpsLength = ((bytes[prefixLength]&0xff)<<8)+bytes[prefixLength+1]&0xff;
        prefixLength += nextSpsLength;
    }
    
    //默认1个
    //    NSInteger ppsCount = bytes[prefixLength]&0xff;
    if (prefixLength+3 >= extraData.length) {
        return nil;
    }
    NSInteger ppsLength = ((bytes[prefixLength+1]&0xff)<<8)+(bytes[prefixLength+2]&0xff);
    NSInteger naluType = (uint8_t)bytes[prefixLength+3]&0x1F;
    if (naluType != 8 || (ppsLength+prefixLength+3) > extraData.length) {
        return nil;
    }
    
    NSData *ppsData = [NSData dataWithBytes:&bytes[prefixLength+3] length:ppsLength];
    return ppsData;
}

- (NSInteger)readFPS {
    
    return 0;
}

- (NSInteger)readPicWidth {
    
    NSInteger sizeIndex = 32;
    [_parser.fileHandle seekToFileOffset:_avccBox.superBox.startIndexInBytes+sizeIndex];
    NSData *widthData = [_parser.fileHandle readDataOfLength:2];
    const char *bytes = widthData.bytes;
    NSInteger width = ((bytes[0]&0xff)<<8)+(bytes[1]&0xff);
    return width;
}

- (NSInteger)readPicHeight {
    
    NSInteger sizeIndex = 34;
    [_parser.fileHandle seekToFileOffset:_avccBox.superBox.startIndexInBytes+sizeIndex];
    NSData *heightData = [_parser.fileHandle readDataOfLength:2];
    const char *bytes = heightData.bytes;
    NSInteger height = ((bytes[0]&0xff)<<8)+(bytes[1]&0xff);
    return height;
}

- (double)readDuration {
    
    NSData *mvhdData = [_parser readDataForBox:_mvhdBox];
    const char *bytes = mvhdData.bytes;
    NSInteger version = [self read32BitValue:&bytes[8]];
    NSInteger timescaleIndex = 20;
    NSInteger timescaleLength = 4;
    NSInteger durationIndex = 24;
    NSInteger durationLength = 4;
    
    if (version == 1) {
        timescaleIndex = 28;
        durationIndex = 32;
        durationLength = 8;
    }
    
    NSInteger scale = [self readValue:&bytes[timescaleIndex] length:timescaleLength];
    NSInteger duration = [self readValue:&bytes[durationIndex] length:durationLength];
    if (scale == 0) {
        return 0;
    }
    double result = duration/(double)scale;
    return result;
}

- (NSArray *)readPacketSizeArr {
    
    NSInteger totalLength = 0;
    do{
        //初始化packet尺寸数组
        //ststsize(32)+ststtype(32)+version(32)+samplesize(32)
        NSData *stszData = [_parser readDataForBox:_stszBox];
        if (stszData.length < 20) {
            return nil;
        }
        const char *stszBytes = stszData.bytes;
        NSInteger sampleSize = [self read32BitValue:&stszBytes[12]];
        NSInteger sampleCount = [self read32BitValue:&stszBytes[16]];
        if (sampleSize != 0) {
            _packtSizes = @[@(sampleSize)];
            break ;
        }
        
        NSMutableArray *sizes = [NSMutableArray new];
        NSInteger sizeStartIndex = 20;
        for (int i =0 ; i < sampleCount; i++,sizeStartIndex+=4) {
            
            if (sizeStartIndex+4 > stszData.length) {
                break ;
            }
            NSInteger entrySize = [self read32BitValue:&stszBytes[sizeStartIndex]];
            [sizes addObject:@(entrySize)];
            totalLength += entrySize;
        }
        _packtSizes = sizes;
    }while(0);
    return _packtSizes;
}

- (NSData *)readNextPacket {
    
    if (!_stszBox) {
        return nil;
    }
    
    NSInteger mdatStartIndex = (NSInteger)_mdatBox.startIndexInBytes + 8;
    NSInteger currentSampleIndex = ++_currentPacketIndex;
    if (currentSampleIndex >= self.packtSizes.count) {
        return nil;
    }
    NSInteger currentSampleSize = [self.packtSizes[currentSampleIndex] integerValue];
    for (NSInteger i = 0; i < currentSampleIndex; i++) {
        NSInteger tempEntrySize = [self.packtSizes[i] integerValue];
        mdatStartIndex += tempEntrySize;
    }
    if (_mdatBox.length < (mdatStartIndex+currentSampleSize-_mdatBox.startIndexInBytes)) {
        return nil;
    }
    [_parser.fileHandle seekToFileOffset:mdatStartIndex];
    NSData *packetData = [_parser.fileHandle readDataOfLength:currentSampleSize];
    return packetData;
}

- (NSInteger)read32BitValue:(const char*)bytes {
    
    NSInteger sampleSize = ((bytes[0]&0xff)<<24)+((bytes[1]&0xff)<<16)+((bytes[2]&0xff)<<8)+(bytes[3]&0xff);
    return sampleSize;
}

- (NSInteger)readValue:(const char*)bytes length:(NSInteger)length {
    
    NSInteger value = 0;
    for (int i = 0; i < length; i++) {
        value += (bytes[i]&0xff)<<((length-i-1)*8);
    }
    return value;
}

#pragma mark -- delegate

- (void)MP4FileDidFinishParse:(QGMP4Parser *)parser {
    
}

- (void)didParseMP4Box:(QGMP4Box *)box parser:(QGMP4Parser *)parser {
    
    switch (box.type) {
        case QGMP4BoxType_mdat:
            _mdatBox = (QGMP4MdatBox*)box;
            break;
        case QGMP4BoxType_avcC:
            _avccBox = (QGMP4AvccBox*)box;
            _stsdBox = (QGMP4StsdBox*)_avccBox.superBox;
            break;
        case QGMP4BoxType_stsz:
            _stszBox = (QGMP4StszBox *)box;
            break;
        case QGMP4BoxType_stsd:
            //_stsdBox = (QGMP4StsdBox *)box;
            break;
        case QGMP4BoxType_mvhd:
            _mvhdBox = (QGMP4MvhdBox *)box;
            break;
        default:
            break;
    }
}

@end
