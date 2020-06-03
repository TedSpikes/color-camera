//
//  ViewController.swift
//  Color Camera
//
//  Created by Ted on 3/11/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewportViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    let cameraManager = CameraManager()
    let filterManager = FilterManager()
    
    let bottomButtonConfig = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 48.0), weight: .regular)
    let upperRightButtonConfig  = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 32.0), weight: .regular)
    
    override var prefersStatusBarHidden: Bool { return true }
    var activeFilter: VisionFilter?
    var cameraEnabled: Bool = true
    private var inGalleryMode: Bool = false
    private var originalGalleryImage: UIImage = UIImage()
    
    // MARK: UI hooks
    @IBOutlet weak var filteredImageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var filterPickerButton: UIButton!
    @IBOutlet weak var bottomButtonsView: UIView!
    @IBOutlet weak var upperRightButtonsView: UIView!
    @IBOutlet weak var imageScrollView: UIScrollView!
    
    @IBAction func beginPhotoCapture(_ sender: UIButton) {
        if inGalleryMode {
            self.saveGalleryPreview()
        } else {
            self.capturePhoto()
        }
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
    
    @IBAction func chooseImage(_ sender: UIButton) {
        if inGalleryMode {
            toggleViewportGalleryMode(enabled: false)
        } else {
            self.pickPhoto()
        }
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
            self.toggleFlashButton.setImage(UIImage(systemName: "flashlight.on.fill", withConfiguration: self.upperRightButtonConfig)?.withTintColor(.white), for: .normal)
            self.toggleFlashButton.tintColor = .white
        } else {
            self.toggleFlashButton.setImage(UIImage(systemName: "flashlight.off.fill", withConfiguration: self.upperRightButtonConfig)?.withTintColor(.white), for: .normal)
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
        self.imageScrollView.minimumZoomScale = 1.0
        self.imageScrollView.maximumZoomScale = 1.0
        
        let doubleTapGr = UITapGestureRecognizer(target: self, action: #selector(ViewportViewController.doubleTapZoom(_:)))
        doubleTapGr.delegate = self
        doubleTapGr.numberOfTapsRequired = 2
        self.imageScrollView.addGestureRecognizer(doubleTapGr)
        
        // Buttons
        self.filterPickerButton.setImage(UIImage(systemName: "list.dash", withConfiguration: self.bottomButtonConfig), for: .normal)
        self.captureButton.setImage(UIImage(systemName: "circle", withConfiguration: self.bottomButtonConfig), for: .normal)
        self.galleryButton.setImage(UIImage(systemName: "photo.on.rectangle", withConfiguration: self.bottomButtonConfig), for: .normal)
        self.filterPickerButton.tintColor = .white
        self.captureButton.tintColor = .white
        self.galleryButton.tintColor = .white
        
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
        self.imageScrollView.delegate = self
        
        self.loadFilterFromStorage()
        self.configureCameraController()
        self.styleElements()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return self.filteredImageView }
    
    @objc func doubleTapZoom(_ sender: UITapGestureRecognizer) {
        if imageScrollView.zoomScale > imageScrollView.minimumZoomScale {
            imageScrollView.setZoomScale(imageScrollView.minimumZoomScale, animated: true)
        } else {
            imageScrollView.setZoomScale(imageScrollView.maximumZoomScale, animated: true)
        }
    }
    
    // MARK: Filter switching logic
    func switchToFilter(name: String) {
        let filter = self.filterManager.filter(withName: name) as! VisionFilter
        self.activeFilter = filter
        if inGalleryMode {
            refreshGalleryImage()
        }
    }

    // MARK: Work with the camera output
    func getFilteredImage(fromCIImage image: CIImage, oriented orientation: CGImagePropertyOrientation = .up) -> UIImage? {
        guard let filter = self.activeFilter else {
            return nil
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        var result = filter.value(forKey: kCIOutputImageKey) as! CIImage
        result = result.oriented(orientation)
        return UIImage(ciImage: result)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        let filteredImage = self.getFilteredImage(fromCIImage: cameraImage) ?? UIImage(ciImage: cameraImage)
        
        if !self.cameraEnabled {
            return
        }
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
    private func flashViewport() {
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
        self.flashViewport()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if error == nil {
        } else {
            print("Failed to capture photo: \(error!)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            if let imageData = photo.fileDataRepresentation() {
                let dataProvider = CGDataProvider(data: imageData as CFData)
                let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                if let filteredImage = self.getFilteredImage(fromCIImage: CIImage(cgImage: cgImageRef), oriented: .right) {
                    let previewPopup = PhotoPreviewViewController(delegate: self, withPreview: filteredImage)
                    self.present(previewPopup, animated: true, completion: nil)
                }
            }
        } else {
            print("Failed to process photo: \(error!)")
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            print("Failed to save an image: \(String(describing: error))")
        } else {
            print("Successfully saved the image: \(image.debugDescription)")
        }
    }
}

// MARK: Working with images from the gallery
extension ViewportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func pickPhoto() {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return
        }
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: nil)
    }
    
    func saveGalleryPreview() {
        if let _image = self.filteredImageView.image {
            if _image.cgImage != nil { // Backed by a CGImage, safe to save
                UIImageWriteToSavedPhotosAlbum(_image, self, #selector(ViewportViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else if _image.ciImage != nil { // Backed by a CIImage, have to convert
                let ciImage: CIImage = _image.ciImage!
                let context = CIContext(options: nil)
                guard let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent) else { return } // TODO: Should throw an error
                let newImage = UIImage(cgImage: cgImage)
                UIImageWriteToSavedPhotosAlbum(newImage, self, #selector(ViewportViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    private func toggleViewportGalleryMode(enabled: Bool) {
        self.inGalleryMode = enabled
        // Restyle the button, set the image view content mode
        if enabled {
            self.galleryButton.setImage(UIImage(systemName: "camera", withConfiguration: self.bottomButtonConfig), for: .normal)
            self.captureButton.setImage(UIImage(systemName: "square.and.arrow.down", withConfiguration: self.bottomButtonConfig), for: .normal)
            self.filteredImageView.contentMode = .scaleAspectFit
            self.upperRightButtonsView.isHidden = true
            self.imageScrollView.minimumZoomScale = 1.0
            self.imageScrollView.maximumZoomScale = 6.0
        } else {
            self.galleryButton.setImage(UIImage(systemName: "photo.on.rectangle", withConfiguration: self.bottomButtonConfig), for: .normal)
            self.captureButton.setImage(UIImage(systemName: "circle", withConfiguration: self.bottomButtonConfig), for: .normal)
            self.filteredImageView.contentMode = .scaleAspectFill
            self.upperRightButtonsView.isHidden = false
            self.imageScrollView.minimumZoomScale = 1.0
            self.imageScrollView.maximumZoomScale = 1.0
        }
        
        self.cameraEnabled = !enabled // The world's worst line of code
    }
    
    private func refreshGalleryImage() {
        if let _image = originalGalleryImage.ciImage {
            DispatchQueue.main.async {
                self.filteredImageView.image = self.getFilteredImage(fromCIImage: _image)
            }
        } else if let _image = originalGalleryImage.cgImage {
            DispatchQueue.main.async {
                self.filteredImageView.image = self.getFilteredImage(fromCIImage: CIImage(cgImage: _image))
            }
        } else {
            print("Unable to get a filtered image out of \(originalGalleryImage.description)")
            return
        }
    }
    
    // Protocol methods
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true, completion: nil) }
        
        if let _uiImage = info[.originalImage] as? UIImage {
            originalGalleryImage = _uiImage
            refreshGalleryImage()
        } else {
            print("Unable to get the original image from \(info.description)")
            return
        }
        
        self.cameraEnabled = false
        toggleViewportGalleryMode(enabled: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        defer { picker.dismiss(animated: true, completion: nil) }
        print("picker did cancel")
    }
}
