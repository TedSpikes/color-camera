//
//  ViewController.swift
//  Color Camera
//
//  Created by Fedor on 3/11/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let cameraController = CameraController()
    
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var capturePreviewView: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func configureCameraController() {
            cameraController.prepare { (error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.capturePreviewView)
            }
        }
        
        configureCameraController()
    }
}

