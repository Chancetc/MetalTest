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
        
        let hwdMetalView = QGHWDMetalView(frame: CGRect(x: 0, y: 0, width: 368, height: 288))
        hwdMetalView.center = view.center
        view.addSubview(hwdMetalView)
        
        hwdMetalView.display(imageName: "31");
    }
}

