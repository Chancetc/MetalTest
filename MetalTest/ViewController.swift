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

class ViewController: UIViewController {
    
    var mp4View: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bgView = UIImageView.init(image: UIImage.init(named: "bg.PNG"))
        bgView.frame = view.bounds
        view.addSubview(bgView)
        
//        let hwdMetalView = QGHWDMetalView(frame: CGRect(x: 0, y: 0, width: 368, height: 288))
//        hwdMetalView.center = view.center
//        view.addSubview(hwdMetalView)
//        hwdMetalView.display(imageName: "31");
        
        mp4View = UIView(frame: view.bounds)
        view.addSubview(mp4View)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMP4View))
        mp4View.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapMP4View() {
        let resPath = Bundle.main.path(forResource: "gift_1344", ofType: "mp4")
        mp4View.playHWDMP4(resPath!, fps: 0, blendMode: QGHWDTextureBlendMode(rawValue: 0)!, delegate: nil)
    }
}

