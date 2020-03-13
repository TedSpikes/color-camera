//
//  ViewController.swift
//  Color Camera
//
//  Created by Ted on 3/11/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewportViewController: UIViewController {
    let cameraManager = CameraManager()
    let filterManager = FilterManager()
    
    override var prefersStatusBarHidden: Bool { return true }
    var activeFilter: VisionFilter?
    
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
}

// MARK: The setup.
extension ViewportViewController {
    func configureCameraController() {
        cameraManager.prepare(captureVideoDelegate: self) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
       
    func styleButtons() {
        let
        self.captureButton.setImage(<#T##image: UIImage?##UIImage?#>, for: <#T##UIControl.State#>)
    }
    
    func styleFilterPickerButton() {
        self.filterPickerButton.layer.cornerRadius = self.filterPickerButton.frame.height / 2
    }
    
    func loadFilterFromStorage(defaultFilter: String = "Normal") {
        let storedFilter = getStoredFilter()
        self.switchToFilter(name: storedFilter ?? defaultFilter)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadFilterFromStorage()
        self.configureCameraController()
        self.styleButtons()
        self.styleFilterPickerButton()
    }
}

/// Create the filter and switch to it.
extension ViewportViewController {
    func switchToFilter(name: String) {
        let filter = self.filterManager.filter(withName: name) as! VisionFilter
        self.activeFilter = filter
    }
}

/// Receive, process, and display the camera image.
extension ViewportViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func getFilteredImage(fromCIImage image: CIImage) -> UIImage? {
        guard let filter = self.activeFilter else {
            return nil
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        let result = UIImage(ciImage: filter.value(forKey: kCIOutputImageKey) as! CIImage)
        return result
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        
        let filteredImage = self.getFilteredImage(fromCIImage: cameraImage) ?? UIImage(ciImage: cameraImage)
        DispatchQueue.main.async {
            self.filteredImageView.image = filteredImage
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}

// TODO: Capture images to Camera Roll.
