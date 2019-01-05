//
//  QGAdvancedGiftFramesEditor.swift
//  MetalTest
//
//  Created by Chanceguo on 1/5/19.
//  Copyright © 2019 Tencent. All rights reserved.
//

import UIKit

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = self.cgImage!.dataProvider!.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

class QGAdvancedGiftFramesEditor: NSObject {

    class func mergeMaskInfo(config: QGAdvancedGiftAttachmentsConfigModel) {
        
        for index in 0 ... config.framesCount {
            
            print("frame:\(index)")
            let h = index/100
            let t = (index-h*100)/10
            let o = index%10
            let imageName: String = "\(h)\(t)\(o)"
            
            guard let frameModel = config.frames[index] else {
                continue
            }
            guard frameModel.attachments.count > 0 else {
                return
            }
            
            guard let desImage = UIImage.init(named: imageName) else {
                return
            }
            autoreleasepool {
                let desPixelData = CFDataCreateMutableCopy(kCFAllocatorDefault, 0,desImage.cgImage!.dataProvider!.data!)
                let desData: UnsafeMutablePointer<UInt8> = CFDataGetMutableBytePtr(desPixelData)
                
                for attachmentModel in frameModel.attachments {
                    guard let maskmodel = attachmentModel.maskModel else {
                        continue
                    }
                    guard let maskImage = maskmodel.maskImageForFrame(index, directory: "./MetalTest/resource/752_1344") else {
                        continue
                    }
                    autoreleasepool {
                        
                        let rect = CGRect(x: attachmentModel.origin.x-1, y: attachmentModel.origin.y-1, width: attachmentModel.size.width+2, height: attachmentModel.size.height+2)
                        
                        UIGraphicsBeginImageContextWithOptions(desImage.size, false, desImage.scale)
                        maskImage.draw(in: rect)
                        guard let fullMaskImage = UIGraphicsGetImageFromCurrentImageContext() else {
                            return
                        }
                        UIGraphicsEndImageContext()
                        
                        let maskPixelData = fullMaskImage.cgImage!.dataProvider!.data!
                        let maskData: UnsafePointer<UInt8> = CFDataGetBytePtr(maskPixelData)
                        
                        for indexOfHeight in 0 ..< Int(desImage.size.height) {
                            for indexOfWidth in 0 ..< Int(desImage.size.width) {
                                
                                let pixelAIndex: Int = ((Int(desImage.size.width)*indexOfHeight) + indexOfWidth)*4 + 3
                                let pixelGindex = pixelAIndex - 2
                                let pixelBIndex = pixelAIndex - 1
                                
                                let maskA = UInt8(maskData[pixelAIndex])
                                if indexOfWidth >= Int(rect.origin.x)
                                    && indexOfWidth <= Int(rect.origin.x+rect.size.width)
                                    && indexOfHeight >= Int(rect.origin.y)
                                    &&  indexOfHeight <= Int(rect.origin.y+rect.size.height) {
                                    if maskmodel.maskType == .SrcOut {
                                        desData[pixelGindex] = maskA
                                    } else {
                                        desData[pixelBIndex] = maskA
                                    }
                                    
                                }
                            }
                        }
                    }
                }
                
                //frame for attachments[index]
                var dataProvider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, desData, CFDataGetLength(desPixelData)))
                var cgImage = CGImage(width: Int(desImage.size.width), height: Int(desImage.size.height), bitsPerComponent: (desImage.cgImage?.bitsPerComponent)!, bitsPerPixel: (desImage.cgImage?.bitsPerPixel)!, bytesPerRow: (desImage.cgImage?.bytesPerRow)!, space: (desImage.cgImage?.colorSpace)!, bitmapInfo: (desImage.cgImage?.bitmapInfo)!, provider: dataProvider!, decode: nil, shouldInterpolate: false, intent: (desImage.cgImage?.renderingIntent)!)
                
                let img = UIImage.init(cgImage: cgImage!)
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                var destinationPath = documentsPath.appendingPathComponent("\(imageName).png")
                destinationPath = "file://\(destinationPath)"

                do {
                    try img.pngData()!.write(to: URL(string: destinationPath)!)
                } catch {
                    print("error\(error).")
                }
                dataProvider = nil
                cgImage = nil
            
            }
            
        }
   
    print("done!")
    }
}
