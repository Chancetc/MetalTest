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
    private var drawableSizeShouldUpdate: Bool
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        
        drawableSizeShouldUpdate = true
        super.init(frame: frame)
        metalLayer = layer as? CAMetalLayer
        metalLayer.frame = frame
        renderer = QGHWDMetalRenderer(metalLayer: metalLayer)
        //important!
        metalLayer.isOpaque = false
        metalLayer.contentsScale = UIScreen.main.scale
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
    }
    
    override func didMoveToWindow() {
        superview?.didMoveToWindow()
        drawableSizeShouldUpdate = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawableSizeShouldUpdate = true
    }
    
    deinit {
        onMetalViewUnavailable()
    }
    
    @objc func display(pixelBuffer: CVPixelBuffer, attachment: QGAdvancedGiftAttachmentsFrameModel?) {
        
        guard window != nil else {
            onMetalViewUnavailable()
            return
        }
        //update drawable size if need
        if drawableSizeShouldUpdate {
            let nativeScale = window!.screen.nativeScale
            let drawableSize = CGSize(width: bounds.width*nativeScale, height: bounds.height*nativeScale)
            metalLayer.drawableSize = drawableSize
            drawableSizeShouldUpdate = false
        }
        renderer.render(pixelBuffer: pixelBuffer, metalLayer: metalLayer, attachment:attachment)
    }
    
    func onMetalViewUnavailable() {
        
        guard let delegate = delegate else { return }
        delegate.onMetalViewUnavailable()
    }
}
