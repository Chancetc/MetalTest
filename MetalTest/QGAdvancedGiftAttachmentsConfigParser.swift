//
//  QGAdvancedGiftAttachmentsConfigParser.swift
//  MetalTest
//
//  Created by Chanceguo on 2018/12/17.
//  Copyright © 2018 Tencent. All rights reserved.
//

import Foundation

class QGAdvancedGiftAttachmentsConfigParser: NSObject {
    
    class func parse(_ configPath: String?) ->QGAdvancedGiftAttachmentsConfigModel? {
        
        guard let configPath = configPath else { return nil }
        guard let configData: NSData = NSData(contentsOfFile: configPath) else { return nil }
        guard let configDictionary = configData.jsonValueDecoded() as? Dictionary<String, Any> else { return nil }
        return QGAdvancedGiftAttachmentsConfigModel.modelFromConfig(configDictionary)
    }
    
    class func requestSources(model: QGAdvancedGiftAttachmentsConfigModel?, extraInfo: Dictionary<String, Any>?, completion:@escaping (_ model: QGAdvancedGiftAttachmentsConfigModel?, _ success: Bool)->()) {
        
        var anyError = false
        var completed = false
        let serialQueue = DispatchQueue(label: "com.qgame.agSerialQueue")
        let dispatchGroup = DispatchGroup()
        
        guard let model = model else {
            completion(nil, false)
            return
        }
        
        let completionBlock: (Bool)->() = { result in
            serialQueue.sync {
                if completed == true {
                    return
                }
                if result == false {
                    anyError = true
                    completion(nil, result)
                } else {
                    completion(model, result)
                }
                completed = true
            }
        }
        for (_, source) in model.sources {
            
            serialQueue.sync {
                if anyError == true {
                    // abort
                    return
                }
            }
            switch source.sourceType {
            case .ImgUrl:
                guard var url = source.imgUrl else {
                    completionBlock(false)
                    return
                }
                if let extraInfo = extraInfo ,let mappingUrl = extraInfo[url] as? String {
                    url = mappingUrl
                }
                
                guard let URL = URL(string: url) else {
                    completionBlock(false)
                    return
                }
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    YYWebImageManager.shared().requestImage(with: URL, options: .init(rawValue: 0), progress: nil, transform: nil) { (image, downloadURL, type, stage, error) in
                        
                        if image == nil || error != nil {
                            completionBlock(false)
                            dispatchGroup.leave()
                            return
                        }
                        dispatchGroup.leave()
                        //success
                        source.sourceImage = image!
                    }
                }
            case .TextStr:
                
                guard var textStr = source.textStr else {
                    completionBlock(false)
                    return
                }
                if let extraInfo = extraInfo ,let mappingText = extraInfo[textStr] as? String {
                    textStr = mappingText
                }
                
                guard let color = source.color else {
                    completionBlock(false)
                    return
                }
                
                let width = CGFloat(source.width/2.0), height = CGFloat(source.height/2.0)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
                let img = renderer.image { ctx in
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .left
                    paragraphStyle.lineBreakMode = .byTruncatingTail
                    let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: height*0.9), NSAttributedString.Key.paragraphStyle: paragraphStyle,NSAttributedString.Key.foregroundColor: color]
                    textStr.draw(with: CGRect(x: 0, y: 0, width: width, height: height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                }
                source.sourceImage = img
            }
        }
        
        if model.sources.count == 0 {
            completionBlock(false)
        }
        
        dispatchGroup.notify(queue: .main) {
            completionBlock(true)
        }
    }
}
