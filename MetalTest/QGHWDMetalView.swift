//
//  QGHWDMetalView.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import MetalKit

@objc protocol QGHWDMetelViewDelegate {
    
    func onMetalViewUnavailable();
}

class QGHWDMetalView: UIView {
    
    @objc weak var delegate: QGHWDMetelViewDelegate?
    @objc var blendMode: QGHWDTextureBlendMode {
        get {
            return renderer.blendMode
        }
        set {
            renderer.blendMode = newValue
        }
    }
    
    private var metalLayer: CAMetalLayer!
    private var renderer: QGHWDMetalRenderer!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        metalLayer = CAMetalLayer()
        renderer = QGHWDMetalRenderer(metalLayer: metalLayer)
        //important!
        metalLayer.isOpaque = false
        metalLayer.contentsScale = UIScreen.main.scale
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = bounds
        layer.addSublayer(metalLayer)
    }
    
    deinit {
        onMetalViewUnavailable()
    }
    
    @objc func display(pixelBuffer: CVPixelBuffer) {
        
        guard window != nil else {
            onMetalViewUnavailable()
            return
        }
        renderer.render(pixelBuffer: pixelBuffer, metalLayer: metalLayer)
    }
    
    func onMetalViewUnavailable() {
        
        guard let delegate = delegate else { return }
        delegate.onMetalViewUnavailable()
    }
}
