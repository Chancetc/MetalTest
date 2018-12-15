//
//  ViewController.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/12.
//  Copyright © 2018 Tencent. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController, HWDMP4PlayDelegate {

    var mp4View: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bgView = UIImageView.init(image: UIImage.init(named: "bg.PNG"))
        bgView.frame = view.bounds
        view.addSubview(bgView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMP4View))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapMP4View() {
        
        if mp4View != nil {
            mp4View.removeFromSuperview()
        }
        mp4View = UIView(frame: view.bounds)
        view.addSubview(mp4View)
        let resPath = Bundle.main.path(forResource: "gift_1344", ofType: "mp4")
        mp4View.playHWDMP4(resPath!, fps: 0, blendMode: QGHWDTextureBlendMode(rawValue: 0)!, delegate: self)
    }
    
    func viewDidFinishPlayMP4(_ totalFrameCount: Int, view container: UIView!) {
        DispatchQueue.main.async {
            guard let mp4View = self.mp4View else {
                return ;
            }
            if mp4View == container {
                mp4View.removeFromSuperview()
                self.mp4View = nil
            }
        }
    }
    
    func viewDidPlayMP4(at frame: QGMP4AnimatedImageFrame!, view container: UIView!) {
        
    }
    
    func viewDidStopPlayMP4(_ lastFrameIndex: Int, view container: UIView!) {
        
    }
}

