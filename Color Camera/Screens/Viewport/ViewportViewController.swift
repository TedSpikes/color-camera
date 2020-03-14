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
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        do {
            try cameraManager.toggleFlash()
        } catch { print(error) }
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
        let pointSize    = CGFloat(floatLiteral: 36.0)
        
        let normalConfig = UIImage.SymbolConfiguration(pointSize: pointSize)
        let lightConfig  = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .ultraLight)
        
        self.filterPickerButton.setImage(UIImage(systemName: "list.dash", withConfiguration: normalConfig), for: .normal)
        self.filterPickerButton.setImage(UIImage(systemName: "list.dash", withConfiguration: lightConfig), for: .highlighted)
        self.captureButton.setImage(UIImage(systemName: "circle", withConfiguration: normalConfig), for: .normal)
        self.captureButton.setImage(UIImage(systemName: "circle", withConfiguration: lightConfig), for: .highlighted)
        self.toggleFlashButton.setImage(UIImage(systemName: "bolt", withConfiguration: normalConfig), for: .normal)
        self.toggleFlashButton.setImage(UIImage(systemName: "bolt", withConfiguration: lightConfig), for: .highlighted)
        self.toggleCameraButton.setImage(UIImage(systemName: "camera.rotate", withConfiguration: normalConfig), for: .normal)
        self.toggleCameraButton.setImage(UIImage(systemName: "camera.rotate", withConfiguration: lightConfig), for: .selected)
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
