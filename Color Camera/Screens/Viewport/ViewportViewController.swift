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
    
    let bottomButtonConfig = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 48.0), weight: .regular)
    let upperRightButtonConfig  = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 32.0), weight: .regular)
    
    override var prefersStatusBarHidden: Bool { return true }
    var activeFilter: VisionFilter?
    
    // MARK: Interface hooks
    @IBOutlet weak var filteredImageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var filterPickerButton: UIButton!
    @IBOutlet weak var bottomButtonsView: UIView!
    @IBOutlet weak var upperRightButtonsView: UIView!
    
    @IBAction func beginPhotoCapture(_ sender: UIButton) {
        self.capturePhoto()
    }
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        do {
            try self.cameraManager.switchCameras()
        }
        catch {
            print(error)
        }
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        do {
            try self.cameraManager.toggleFlash()
            self.styleFlashButton(isOn: self.cameraManager.isFlashOn)
        } catch { print(error) }
    }
    
    @IBAction func pickFilter(_ sender: UIButton) {
        let filterPicker = FilterPickerViewController(nibName: "FilterPickerView", bundle: nil)
        self.present(filterPicker, animated: true, completion: nil)
    }

    // MARK: The setup
    func configureCameraController() {
        self.cameraManager.prepare(captureVideoDelegate: self) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
    
    func styleFlashButton(isOn: Bool) {
        if isOn {
            self.toggleFlashButton.setImage(UIImage(systemName: "bolt.fill", withConfiguration: self.upperRightButtonConfig)?.withTintColor(.white), for: .normal)
            self.toggleFlashButton.tintColor = .white
        } else {
            self.toggleFlashButton.setImage(UIImage(systemName: "bolt", withConfiguration: self.upperRightButtonConfig)?.withTintColor(.white), for: .normal)
            self.toggleFlashButton.tintColor = .white
        }
    }
       
    func styleElements() {
        // Views
        self.view.backgroundColor = .black
        self.bottomButtonsView.layer.cornerRadius = 8
        self.bottomButtonsView.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        self.upperRightButtonsView.layer.cornerRadius = 4
        self.upperRightButtonsView.backgroundColor = UIColor(white: 0.1, alpha:  0.75)
        self.filteredImageView.contentMode = .scaleAspectFill
        
        // Buttons
        self.filterPickerButton.setImage(UIImage(systemName: "list.dash", withConfiguration: self.bottomButtonConfig), for: .normal)
        self.captureButton.setImage(UIImage(systemName: "circle", withConfiguration: self.bottomButtonConfig), for: .normal)
        self.filterPickerButton.tintColor = .white
        self.captureButton.tintColor = .white
        
        self.styleFlashButton(isOn: self.cameraManager.isFlashOn)
        self.toggleCameraButton.setImage(UIImage(systemName: "camera.rotate", withConfiguration: self.upperRightButtonConfig)?.withTintColor(.white), for: .normal)
        self.toggleCameraButton.tintColor = .white
    }
    
    func loadFilterFromStorage(defaultFilter: String = "Normal") {
        let storedFilter = getStoredFilter()
        self.switchToFilter(name: storedFilter ?? defaultFilter)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadFilterFromStorage()
        self.configureCameraController()
        self.styleElements()
    }
    
    // MARK: Filter switching logic
    func switchToFilter(name: String) {
        let filter = self.filterManager.filter(withName: name) as! VisionFilter
        self.activeFilter = filter
    }

    // MARK: Work with the camera output
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
            if self.cameraManager.cameraPosition == .front {
                // Mirror the image view for front camera
                self.filteredImageView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            } else {
                self.filteredImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    // MARK: Capture photos
    private func buildCaptureSettings() -> AVCapturePhotoSettings {
        /// Simplified magic from https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        var photoSettings = AVCapturePhotoSettings()
        let previewPixelType = photoSettings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                     kCVPixelBufferWidthKey as String: 160,
                                     kCVPixelBufferHeightKey as String: 160,
                                     ]
        photoSettings.previewPhotoFormat = previewFormat
        if  self.cameraManager.cameraPhotoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        if (self.cameraManager.frontCameraInput?.device.isFlashAvailable ?? false) || (self.cameraManager.rearCameraInput?.device.isFlashAvailable ?? false) {
            photoSettings.flashMode = .auto
        }
        photoSettings.photoQualityPrioritization = .balanced
        return photoSettings
    }
    
    func capturePhoto() {
        let captureSettings = buildCaptureSettings()
        self.cameraManager.cameraPhotoOutput!.capturePhoto(with: captureSettings, delegate: self)
    }
}

extension ViewportViewController: AVCaptureVideoDataOutputSampleBufferDelegate {}

extension ViewportViewController: AVCapturePhotoCaptureDelegate {
    private func flashViewPort() {
        self.filteredImageView.layer.opacity = 0
        UIView.animate(withDuration: 0.25) {
            self.filteredImageView.layer.opacity = 1
        }
    }
    
    // MARK: Capture delegate methods
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.flashViewPort()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if error == nil {
        } else {
            print("Failed to capture photo: \(error!)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            print("\(photo.description)")
            if let imageData = photo.fileDataRepresentation() {
                if let image = UIImage(data: imageData) {
                    let previewPopup = PhotoPreviewViewController(withPreview: image)
                    self.present(previewPopup, animated: true, completion: nil)
                }
            }
        } else {
            print("Failed to process photo: \(error!)")
        }
    }
}
