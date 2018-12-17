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
        
        print(configDictionary)
        
        return QGAdvancedGiftAttachmentsConfigModel.modelFromConfig(configDictionary)
    }
}
