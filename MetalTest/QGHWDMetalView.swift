//
//  QGHWDMetalView.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import MetalKit

class QGHWDMetalView: UIView {
    
    var metalLayer: CAMetalLayer!
    var renderer: QGHWDMetalRenderer!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        metalLayer = CAMetalLayer()
        renderer = QGHWDMetalRenderer(metalLayer: metalLayer)
//        metalLayer.backgroundColor = UIColor.blue.cgColor
        //important!
        metalLayer.isOpaque = false
        metalLayer.contentsScale = UIScreen.main.scale
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = bounds
        layer.addSublayer(metalLayer)
    }
    
    @objc func display(imageName: String) {
        
        guard let texture = try? QGHWDMetalRenderer.loadTexture(imageName: imageName) else { return }
        renderer.render(texture: texture, metalLayer: metalLayer)
    }
    
    @objc func display(pixelBuffer: CVPixelBuffer) {
        
        renderer.render(pixelBuffer: pixelBuffer, metalLayer: metalLayer)
    }
}
