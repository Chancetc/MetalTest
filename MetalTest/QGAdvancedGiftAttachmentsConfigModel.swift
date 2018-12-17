//
//  QGAdvancedGiftAttachmentsConfigModel.swift
//  MetalTest
//
//  Created by Chanceguo on 2018/12/17.
//  Copyright © 2018 Tencent. All rights reserved.
//

import Foundation

//资源适配类型
enum QGAGAttachmentFitType: String {
    case FitXY = "fitXY"            //按指定尺寸缩放
    case CenterFull = "centerFull"    //默认按资源尺寸展示，如果资源尺寸小于遮罩，则等比缩放至可填满
}

enum QGAGAttachmentSourceType: String {
    case UserName = "textUser"          //用户昵称
    case AnchorName = "textAnchor"      //主播昵称
    case AnchorAvatar = "imgAnchor"     //主播头像
    case UserAvatar = "imgUser"         //用户头像
}

enum QGAGAttachmentMaskType: String {
    case SrcOut = "srcOut"  //表示去除遮挡区域
    case SrceIn = "srcIn"   //表示根据遮罩形状裁剪
    case SrcMix = "srcMix"  //表示根据遮罩形状裁剪，再与遮罩混合（带alpha）
}

// MARK: - 资源
class QGAdvancedGiftAttachmentsSourceModel: NSObject {
    
    var sourceId = ""
    var imgUrl: String?
    var width: Float = 0.0
    var height: Float = 0.0
    var color: UIColor?
    var textStr: String?
    var index = 0
    var fitType: QGAGAttachmentFitType = .FitXY
    var sourceType: QGAGAttachmentSourceType = .UserAvatar
    
    override init() {
        super.init()
    }
    
    convenience init(srcId: String, url: String?, w: Float, h: Float, color: UIColor?, text: String?, indexOfSource: Int, fitTypeOfSource: QGAGAttachmentFitType, sourceTypeOfSource: QGAGAttachmentSourceType) {

        self.init()
        sourceId = srcId
        imgUrl = url
        width = w
        height = h
        textStr = text
        index = indexOfSource
        fitType = fitTypeOfSource
        sourceType = sourceTypeOfSource
        self.color = color
    }
}

//MARK: - 遮罩
class QGAdvancedGiftAttachmentsMaskModel: NSObject {
    
    //MARK: - 遮罩某一帧信息
    class QGAdvancedGiftAttachmentsMaskFrame: NSObject {
        
        var index: Int = 0
        var origin: CGPoint
        var size: CGSize
        
        override init() {
            
            origin = CGPoint(x: 0.0, y: 0.0)
            size = CGSize(width: 0.0, height: 0.0)
            super.init()
        }
        
        convenience init(index: Int, origin: CGPoint, size: CGSize) {
            
            self.init()
            self.origin = origin;
            self.size = size
        }
    }
    
    var maskType: QGAGAttachmentMaskType = .SrceIn
    var maskName = ""
    var width: Float = 0.0
    var height: Float = 0.0
    var maskId = ""
    var maskFrames: [Int:QGAdvancedGiftAttachmentsMaskFrame] = [Int:QGAdvancedGiftAttachmentsMaskFrame]()
    
    convenience init(type: QGAGAttachmentMaskType, name: String, w: Float, h: Float, id: String, frames: NSArray) {
        
        self.init()
        maskType = type
        maskName = name
        width = w
        height = h
        maskId = id
        maskFrames = framesFromConfigArr(frames)
    }
    
    func framesFromConfigArr(_ framesArr: NSArray) -> [Int:QGAdvancedGiftAttachmentsMaskFrame] {
        
        var framesDic: Dictionary<Int, QGAdvancedGiftAttachmentsMaskFrame> = Dictionary.init()
        for frameDic in framesArr {
            guard let frameDic = frameDic as? NSDictionary else {
                continue
            }
            guard let index = frameDic["i"] as? Int else { continue }
            guard let width = frameDic["mw"] as? CGFloat else { continue }
            guard let height = frameDic["mh"] as? CGFloat else { continue }
            guard let originX = frameDic["mx"] as? CGFloat else { continue }
            guard let originY = frameDic["my"] as? CGFloat else { continue }
            let frameModel = QGAdvancedGiftAttachmentsMaskFrame(index: index, origin: CGPoint(x: originX, y: originY), size: CGSize(width: width, height: height))
            framesDic[index] = frameModel
        }
        return framesDic
    }
    
    func maskImageForFrame(_ index: Int, directory: NSString) -> UIImage? {
        
        guard let maskFrameModel = maskFrames[index] else { return nil }
        guard let totalMask = UIImage(contentsOfFile:directory.appendingPathComponent(maskName)) else { return nil }
//        let mask = totalMask.rect
        return nil
    }
}

//MARK: - 帧信息
class QGAdvancedGiftAttachmentsFrameModel: NSObject {
    
    //MARK: -- attachment
    class QGAdvancedGiftAttachmentModel: NSObject {
        
        var index: Int = 0  //绘制顺序
        var origin: CGPoint
        var size: CGSize
        var alpha: Float = 1.0
        var sourceId: String = ""
        var sourceModel: QGAdvancedGiftAttachmentsSourceModel!
        var maskId: String = ""
        var maskModel: QGAdvancedGiftAttachmentsMaskModel!
        
        override init() {
            origin = CGPoint(x: 0.0, y: 0.0)
            size = CGSize(width: 0.0, height: 0.0)
            super.init()
        }
        
        convenience init(index: Int, origin: CGPoint, size: CGSize, alpha: Float, sourceId: String, maskId: String) {
            
            self.init()
            self.index = index
            self.origin = origin
            self.size = size
            self.alpha = alpha
            self.sourceId = sourceId
            self.maskId = maskId
        }
    }
    
    var index: Int = 0
    var attachments: [QGAdvancedGiftAttachmentModel] = []
    
    override init() {
        super.init()
    }
    
    convenience init(index: Int, attachments: NSArray) {
        
        self.init()
        self.index = index
        self.attachments = attachmentsFromConfigArr(attachments)
    }
    
    func attachmentsFromConfigArr(_ configArr: NSArray) -> [QGAdvancedGiftAttachmentModel] {
        
        var attachmentsArr: [QGAdvancedGiftAttachmentModel] = Array.init()
        for attachmentObj in configArr {
            
            guard let attachmentObj = attachmentObj as? NSDictionary else {
                continue
            }
            guard let index = attachmentObj["z"] as? Int else { continue }
            guard let alpha = attachmentObj["a"] as? Int else { continue }
            guard let width = attachmentObj["w"] as? CGFloat else { continue }
            guard let height = attachmentObj["h"] as? CGFloat else { continue }
            guard let originX = attachmentObj["x"] as? CGFloat else { continue }
            guard let originY = attachmentObj["y"] as? CGFloat else { continue }
            guard let sourceId = attachmentObj["srcId"] as? String else { continue }
            guard let maskId = attachmentObj["maskId"] as? String else { continue }
            let attachment = QGAdvancedGiftAttachmentModel(index: index, origin: CGPoint(x: originX, y: originY), size: CGSize(width: width, height: height), alpha: Float(alpha)/255.0, sourceId: sourceId, maskId: maskId)
            attachmentsArr.append(attachment)
        }
        //根据zindex重新排序
        attachmentsArr = attachmentsArr.sorted(by: { (model0, model1) -> Bool in
            return (model0.index < model1.index)
        })
        
        return attachmentsArr
    }
}

// MARK: - 配置信息
class QGAdvancedGiftAttachmentsConfigModel: NSObject {
    
    var version: Int = 1
    var framesCount: Int = 0
    var width: Float = 0.0
    var height: Float = 0.0
    
    var sources: [String:QGAdvancedGiftAttachmentsSourceModel] = [String:QGAdvancedGiftAttachmentsSourceModel]()
    var masks: [String:QGAdvancedGiftAttachmentsMaskModel] = [String:QGAdvancedGiftAttachmentsMaskModel]()
    var frames: [Int: QGAdvancedGiftAttachmentsFrameModel] = [Int: QGAdvancedGiftAttachmentsFrameModel]()

    class func modelFromConfig(_ dic: Dictionary<String, Any>?) -> QGAdvancedGiftAttachmentsConfigModel? {
        
        return QGAdvancedGiftAttachmentsConfigModel(dic)
    }
    
    init?(_ dic: Dictionary<String, Any>?) {
        
        super.init()
        guard let dic = dic else { return nil }
        guard let basicInfo: NSDictionary = dic["info"] as? NSDictionary else { return nil }
        guard let sources: NSArray = dic["src"] as? NSArray else { return nil }
        guard let masks: NSArray = dic["mask"] as? NSArray else { return nil }
        guard let frames: NSArray = dic["frame"] as? NSArray else { return nil }
        
        guard parseBasicInfo(basicInfo) else {
            return nil
        }
        
        guard parseSources(sources) else {
            return nil
        }
        
        guard parseMaskInfo(masks) else {
            return nil
        }
        
        guard parseFramesInfo(frames) else {
            return nil
        }
        //根据当前的信息部署内部结构
        deployWithCurrentInfo()
    }
    
    func parseBasicInfo(_ basicInfo: NSDictionary) -> Bool{
        
        guard let v = basicInfo["v"] as? Int else { return false }
        guard let f = basicInfo["f"] as? Int else { return false }
        guard let w = basicInfo["w"] as? Float else { return false }
        guard let h = basicInfo["h"] as? Float else { return false }
        if v <= 0 || f <= 0 || w <= 0.0 || h <= 0.0 {
            return false
        }
        version = v
        framesCount = f
        width = w
        height = h
        return true
    }
    
    func parseSources(_ sourcesArr: NSArray) -> Bool {
        
        var sourcesDict: Dictionary<String, QGAdvancedGiftAttachmentsSourceModel> = Dictionary.init()
        for sourceDic in sourcesArr {
            
            guard let sourceDic = sourceDic as? NSDictionary else {
                continue
            }
            let imgUrl = sourceDic["imgUrl"] as? String
            guard let srcId = sourceDic["srcId"] as? String else { continue }
            guard let width = sourceDic["w"] as? Float else { continue }
            guard let height = sourceDic["h"] as? Float else { continue }
            guard let fitTypeStr = sourceDic["fitType"] as? String else { continue }
            guard let fitType = QGAGAttachmentFitType(rawValue: fitTypeStr) else { continue }
            let text = sourceDic["textStr"] as? String
            var color: UIColor?
            if let colorStr = sourceDic["color"] as? String {
                color = UIColor(hexString: colorStr)
            }
            guard let index = sourceDic["z"] as? Int else { continue }
            guard let sourceTypeStr = sourceDic["srcType"] as? String else { continue }
            guard let sourceType = QGAGAttachmentSourceType(rawValue: sourceTypeStr) else { continue }
            
            let sourceModel = QGAdvancedGiftAttachmentsSourceModel(srcId: srcId, url: imgUrl, w: width, h: height, color:color, text: text, indexOfSource: index, fitTypeOfSource: fitType, sourceTypeOfSource: sourceType)
            sourcesDict[srcId] = sourceModel
        }
        
        if sourcesDict.count == 0 {
            return false
        }
        self.sources = sourcesDict
        return true
    }
    
    func parseMaskInfo(_ masksArr: NSArray) -> Bool {
        
        var masksDict: Dictionary<String, QGAdvancedGiftAttachmentsMaskModel> = Dictionary.init()
        for maskDic in masksArr {
            
            guard let maskDic = maskDic as? NSDictionary else {
                continue
            }
            guard let maskId = maskDic["maskId"] as? String else { continue }
            guard let maskName = maskDic["maskName"] as? String else { continue }
            guard let width = maskDic["w"] as? Float else { continue }
            guard let height = maskDic["h"] as? Float else { continue }
            guard let frames = maskDic["frame"] as? NSArray else { continue }
            guard let maskTypeStr = maskDic["maskType"] as? String else { continue }
            guard let maskType = QGAGAttachmentMaskType(rawValue: maskTypeStr) else { continue }
            let maskModel = QGAdvancedGiftAttachmentsMaskModel(type: maskType, name: maskName, w: width, h: height, id: maskId, frames: frames)
            masksDict[maskId] = maskModel
        }
        self.masks = masksDict
        return true
    }
    
    func parseFramesInfo(_ framesArr: NSArray) -> Bool {
        
        var frames: [Int: QGAdvancedGiftAttachmentsFrameModel] = Dictionary.init()
        for frameDic in framesArr {
            guard let frameDic = frameDic as? NSDictionary else {
                continue
            }
            guard let index = frameDic["i"] as? Int else { continue }
            guard let attachments = frameDic["obj"] as? NSArray else { continue }
            let frame = QGAdvancedGiftAttachmentsFrameModel(index: index, attachments: attachments)
            frames[index] = frame
        }
        self.frames = frames
        return true
    }
    
    func deployWithCurrentInfo() {
        
        var invalidFrames: [Int] = Array.init()
        for (frameIndex, frameModel) in frames {
            for attachModel in frameModel.attachments {
                let sourceModel = sources[attachModel.sourceId]
                let maskModel = masks[attachModel.maskId]
                if sourceModel == nil || maskModel == nil {
                    //invalid model
                    invalidFrames.append(frameIndex)
                    continue
                }
                let maskFrameModel = maskModel?.maskFrames[frameIndex]
                if maskFrameModel == nil {
                    //如果配置的遮罩没有这一帧对应的信息 则也不合法
                    invalidFrames.append(frameIndex)
                    continue
                }
                attachModel.sourceModel = sourceModel
                attachModel.maskModel = maskModel
            }
        }
        
        for frameIndex in invalidFrames {
            frames.removeValue(forKey: frameIndex)
        }
    }
}
