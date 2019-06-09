//
//  ViewController.swift
//  Color Camera
//
//  Created by Fedor on 3/11/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    let cameraManager = CameraManager()
    let filterManager = FilterManager()
    
    @IBOutlet weak var filteredImageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var filterPickerButton: UIButton!
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        do {
            try cameraManager.switchCamera()
        }
        catch {
            print(error)
        }

        switch cameraManager.currentCameraPosition {
        case .some(.front):
            toggleCameraButton.setImage(UIImage(named: "rearCameraIcon"), for: .normal)
            
        case .some(.rear):
            toggleCameraButton.setImage(UIImage(named: "frontCameraIcon"), for: .normal)
            
        case .none:
            return
        }
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        do {
            try cameraManager.toggleFlash()
        } catch { print(error) }
        
        if cameraManager.flashStatus ?? true {
            self.toggleFlashButton.setImage(UIImage(named: "flashOffIcon"), for: .normal)
        } else {
            self.toggleFlashButton.setImage(UIImage(named: "flashOnIcon"), for: .normal)
        }
    }
    
    @IBAction func pickFilter(_ sender: UIButton) {
        let filterPicker = FilterPickerViewController(nibName: "FilterPickerView", bundle: nil)
        self.present(filterPicker, animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool { return true }
}

extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func configureCameraController() {
            cameraManager.prepare(captureVideoDelegate: self) { (error) in
                if let error = error {
                    print(error)
                }
            }
        }
        
        func styleCaptureButton() {
            captureButton.layer.borderColor = UIColor.black.cgColor
            captureButton.layer.borderWidth = 2
            
            captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        }
        
        func styleFilterPickerButton() {
            filterPickerButton.layer.cornerRadius = filterPickerButton.frame.height / 2
        }
        
        configureCameraController()
        styleCaptureButton()
        styleFilterPickerButton()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        
        let invertColors = filterManager.filter(withName: "Protanopia")
        invertColors!.setValue(cameraImage, forKey: kCIInputImageKey)
        let filteredImage = UIImage(ciImage: invertColors!.value(forKey: kCIOutputImageKey) as! CIImage)
        
        DispatchQueue.main.async {
            self.filteredImageView.image = filteredImage
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
