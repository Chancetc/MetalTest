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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let hwdMetalView = QGHWDMetalView(frame: CGRect(x: 0, y: 0, width: 368, height: 288))
//        hwdMetalView.center = view.center
//        view.addSubview(hwdMetalView)
//        hwdMetalView.display(imageName: "31");
        
        let mp4View = UIView(frame: CGRect(x: 0, y: 0, width: 376, height: 376))
        mp4View.center = view.center
        view.addSubview(mp4View)
        
        let resPath = Bundle.main.path(forResource: "test", ofType: "mp4")
        mp4View.playHWDMP4(resPath!, fps: 0, blendMode: QGHWDTextureBlendMode(rawValue: 0)!, delegate: nil)
    }
}

