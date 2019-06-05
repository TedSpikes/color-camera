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
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        do {
            try cameraController.switchCamera()
        }
        catch {
            print(error)
        }

        switch cameraController.currentCameraPosition {
        case .some(.front):
            toggleCameraButton.setImage(UIImage(named: "rearCameraIcon"), for: .normal)
            
        case .some(.rear):
            toggleCameraButton.setImage(UIImage(named: "frontCameraIcon"), for: .normal)
            
        case .none:
            return
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
}

extension ViewController {
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
        
        func styleCaptureButton() {
            captureButton.layer.borderColor = UIColor.black.cgColor
            captureButton.layer.borderWidth = 2
            
            captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        }
        
        configureCameraController()
        styleCaptureButton()
    }
}

