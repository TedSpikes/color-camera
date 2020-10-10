//
//  ViewController.swift
//  Color Camera
//
//  Created by Ted on 3/11/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import UIKit
import AVFoundation
import os.log

class ViewportViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    let cameraManager = CameraManager()
    let filterManager = FilterManager()
    let filterPicker  = FilterPickerViewController(nibName: "FilterPickerView", bundle: nil)
    
    let bottomButtonConfig = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 32.0), weight: .regular)
    let upperRightButtonConfig  = UIImage.SymbolConfiguration(pointSize: CGFloat(floatLiteral: 24.0), weight: .regular)
    
    override var prefersStatusBarHidden: Bool { return true }
    var activeFilter: VisionFilter?
    var cameraEnabled: Bool = true
    private var inGalleryMode: Bool = false
    internal var shouldUseCompactPicker: Bool = true
    private var originalGalleryImage: UIImage = UIImage()
    private var configurationError: Error?
    
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
            saveGalleryPreview()
        } else {
            capturePhoto()
        }
    }
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        do {
            try cameraManager.switchCameras()
            if cameraManager.isFlashOn {
                try cameraManager.toggleFlash()
                styleFlashButton(isOn: false)
            }
            if cameraManager.cameraPosition == .front {
                toggleFlashButton.isEnabled = false
            } else {
                toggleFlashButton.isEnabled = true
            }
        } catch {
            Toast.show(message: "Coudn't switch cameras: \(error)", controller: self)
        }
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        do {
            try cameraManager.toggleFlash()
            styleFlashButton(isOn: cameraManager.isFlashOn)
        } catch {
            Toast.show(message: "Coudn't toggle the flash: \(error)", controller: self)
        }
    }
    
    @IBAction func pickFilter(_ sender: UIButton) {
        showPicker(compactMode: shouldUseCompactPicker)
    }
    
    @IBAction func chooseImage(_ sender: UIButton) {
        if inGalleryMode {
            toggleViewportGalleryMode(enabled: false)
            imageScrollView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        } else {
            pickPhoto()
        }
    }
    
    // MARK: The setup
    func configureCameraController() {
        cameraManager.prepare(captureVideoDelegate: self) { error in
            if let _err = error {
                self.configurationError = _err
            }
        }
    }
    
    func styleFlashButton(isOn: Bool) {
        if isOn {
            toggleFlashButton.setImage(UIImage(systemName: "flashlight.on.fill", withConfiguration: upperRightButtonConfig)?.withTintColor(.white), for: .normal)
            toggleFlashButton.tintColor = .white
        } else {
            toggleFlashButton.setImage(UIImage(systemName: "flashlight.off.fill", withConfiguration: upperRightButtonConfig)?.withTintColor(.white), for: .normal)
            toggleFlashButton.tintColor = .white
        }
    }
       
    func styleElements() {
        // Views
        view.backgroundColor = .black
        bottomButtonsView.layer.cornerRadius = 8
        bottomButtonsView.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        upperRightButtonsView.layer.cornerRadius = 4
        upperRightButtonsView.backgroundColor = UIColor(white: 0.1, alpha:  0.75)
        filteredImageView.contentMode = .scaleAspectFill
        imageScrollView.minimumZoomScale = 1.0
        imageScrollView.maximumZoomScale = 1.0
        
        let doubleTapGr = UITapGestureRecognizer(target: self, action: #selector(ViewportViewController.doubleTapZoom(_:)))
        doubleTapGr.delegate = self
        doubleTapGr.numberOfTapsRequired = 2
        imageScrollView.addGestureRecognizer(doubleTapGr)
        
        // Buttons
        filterPickerButton.setImage(UIImage(systemName: "list.dash", withConfiguration: bottomButtonConfig), for: .normal)
        captureButton.setImage(UIImage(systemName: "circle", withConfiguration: bottomButtonConfig), for: .normal)
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle", withConfiguration: bottomButtonConfig), for: .normal)
        filterPickerButton.tintColor = .white
        captureButton.tintColor = .white
        galleryButton.tintColor = .white
        
        styleFlashButton(isOn: cameraManager.isFlashOn)
        toggleCameraButton.setImage(UIImage(systemName: "camera.rotate", withConfiguration: upperRightButtonConfig)?.withTintColor(.white), for: .normal)
        toggleCameraButton.tintColor = .white
    }
    
    func loadFilterFromStorage(defaultFilter: String = "No filter") {
        var storedFilter = getStoredFilter()
        if let _filter = storedFilter {
            if !filterManager.getFilterNames().contains(_filter) {
                storedFilter = nil
            }
        }
        switchToFilter(name: storedFilter ?? defaultFilter)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageScrollView.delegate = self
        filterPicker.delegate = self
        
        loadFilterFromStorage()
        shouldUseCompactPicker = true //getIsPickerCompact() ?? true
        configureCameraController()
        styleElements()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _err = self.configurationError {
            if let managerError = _err as? CameraManagerError {
                self.present(
                    Toast.getAlertController(titled: managerError.rawValue,
                                             reading: "An error occured when configuring cameras: \(managerError.rawValue)"),
                    animated: true,
                    completion: nil)
                os_log(.error, "An error occured when configuring cameras: %s", managerError.rawValue)
            } else {
                self.present(
                    Toast.getAlertController(titled: "Error",
                                             reading: "An unkown error occured when configuring cameras: \(_err.localizedDescription)"),
                    animated: true,
                    completion: nil)
                os_log(.error, "An unkown error occured when configuring cameras: %s", _err.localizedDescription)
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return filteredImageView }
    
    @objc func doubleTapZoom(_ sender: UITapGestureRecognizer) {
        if imageScrollView.zoomScale > imageScrollView.minimumZoomScale {
            imageScrollView.setZoomScale(imageScrollView.minimumZoomScale, animated: true)
        } else {
            imageScrollView.setZoomScale(imageScrollView.maximumZoomScale, animated: true)
        }
    }
    
    // MARK: Filter switching logic
    func switchToFilter(name: String) {
        let filter = filterManager.filter(withName: name) as! VisionFilter
        activeFilter = filter
        if inGalleryMode {
            refreshGalleryImage()
        }
    }

    // MARK: Work with the camera output
    func getFilteredImage(fromCIImage image: CIImage, oriented orientation: CGImagePropertyOrientation = .up) -> UIImage? {
        guard let filter = activeFilter else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        guard var result: CIImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else { return nil }
        result = result.oriented(orientation)
        return UIImage(ciImage: result)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        let filteredImage = getFilteredImage(fromCIImage: cameraImage) ?? UIImage(ciImage: cameraImage)
        
        if !cameraEnabled {
            return
        }
        DispatchQueue.main.async {
            self.filteredImageView.image = filteredImage
            if self.cameraManager.cameraPosition == .front {
                // Mirror the image view for front camera
                self.imageScrollView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            } else {
                self.imageScrollView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    // MARK: Capture photos
    private func buildCaptureSettings() -> AVCapturePhotoSettings {
        /// Simplified magic from https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        var photoSettings = AVCapturePhotoSettings()
        let previewPixelType = photoSettings.__availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                     kCVPixelBufferWidthKey as String: 160,
                                     kCVPixelBufferHeightKey as String: 160,
                                     ]
        photoSettings.previewPhotoFormat = previewFormat
        if  cameraManager.cameraPhotoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        if (cameraManager.frontCameraInput?.device.isFlashAvailable ?? false) || (cameraManager.rearCameraInput?.device.isFlashAvailable ?? false) {
            photoSettings.flashMode = .auto
        }
        photoSettings.photoQualityPrioritization = .balanced
        return photoSettings
    }
    
    func capturePhoto() {
        if cameraManager.cameraPhotoOutput == nil {
            do {
                try CameraManager.checkPermissions()
            } catch {
                Toast.show(message: "Not allowed to use the camera", controller: self)
            }
        } else {
            let captureSettings = buildCaptureSettings()
            cameraManager.cameraPhotoOutput!.capturePhoto(with: captureSettings, delegate: self)
        }
    }
}

extension ViewportViewController: AVCaptureVideoDataOutputSampleBufferDelegate {}

extension ViewportViewController: AVCapturePhotoCaptureDelegate {
    private func flashViewport() {
        filteredImageView.layer.opacity = 0
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
        flashViewport()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let _error = error {
            Toast.show(message: "Capture failed: \(_error)", controller: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            if let cgImageRepr   = photo.cgImageRepresentation() {
                if let filteredImage = getFilteredImage(fromCIImage: CIImage(cgImage: cgImageRepr.takeUnretainedValue()), oriented: .right) {
                    let previewPopup = PhotoPreviewViewController(delegate: self, withPreview: filteredImage)
                    present(previewPopup, animated: true, completion: nil)
                } else {
                    Toast.show(message: "Capture failed: couldn't get a filtered image", controller: self)
                }
            } else {
                Toast.show(message: "Capture failed: couldn't get cgImageRepresentation", controller: self)
            }
        } else {
            Toast.show(message: "Failed to process photo: \(String(describing: error))", controller: self)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            Toast.show(message: "Failed to save the image: \(String(describing: error))", controller: self)
        } else {
            Toast.show(message: "Image saved", controller: self)
        }
    }
}

// MARK: Working with the gallery
extension ViewportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func pickPhoto() {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return
        }
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }
    
    func saveGalleryPreview() {
        if let _image = filteredImageView.image {
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
        inGalleryMode = enabled
        // Restyle the button, set the image view content mode
        if enabled {
            galleryButton.setImage(UIImage(systemName: "camera", withConfiguration: bottomButtonConfig), for: .normal)
            captureButton.setImage(UIImage(systemName: "square.and.arrow.down", withConfiguration: bottomButtonConfig), for: .normal)
            filteredImageView.contentMode = .scaleAspectFit
            upperRightButtonsView.isHidden = true
            imageScrollView.minimumZoomScale = 1.0
            imageScrollView.maximumZoomScale = 6.0
        } else {
            galleryButton.setImage(UIImage(systemName: "photo.on.rectangle", withConfiguration: bottomButtonConfig), for: .normal)
            captureButton.setImage(UIImage(systemName: "circle", withConfiguration: bottomButtonConfig), for: .normal)
            filteredImageView.contentMode = .scaleAspectFill
            upperRightButtonsView.isHidden = false
            imageScrollView.minimumZoomScale = 1.0
            imageScrollView.maximumZoomScale = 1.0
            imageScrollView.zoomScale = 1.0
        }
        
        cameraEnabled = !enabled // The world's worst line of code
    }
    
    private func refreshGalleryImage() {
        if let _image = originalGalleryImage.ciImage {
            DispatchQueue.main.async {
                self.filteredImageView.image = self.getFilteredImage(fromCIImage: _image,
                                                                     oriented: CGImagePropertyOrientation(self.originalGalleryImage.imageOrientation))
            }
        } else if let _image = originalGalleryImage.cgImage {
            DispatchQueue.main.async {
                self.filteredImageView.image = self.getFilteredImage(fromCIImage: CIImage(cgImage: _image),
                                                                     oriented: CGImagePropertyOrientation(self.originalGalleryImage.imageOrientation))
            }
        } else {
            Toast.show(message: "Error: Unable to process the gallery image data.", controller: self)
            return
        }
    }
    
    // Protocol methods
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true, completion: nil) }
        
        if let _uiImage = info[.originalImage] as? UIImage {
            originalGalleryImage = _uiImage
            imageScrollView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            refreshGalleryImage()
        } else {
            Toast.show(message: "Error: Couldn't get the original image from the picker.", controller: self)
            return
        }
        
        cameraEnabled = false
        toggleViewportGalleryMode(enabled: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        do { picker.dismiss(animated: true, completion: nil) }
    }
}

// MARK: Managing the filter picker controller
extension ViewportViewController: IFilterPickerDelegate {
    func showPicker(compactMode: Bool) {
        if shouldUseCompactPicker {
            let pickerWidth  = view.frame.width
            let pickerHeight = view.frame.height / 2
            let initialFrame = CGRect(x: 0, y: view.frame.height, width: pickerWidth, height: pickerHeight)
            let frame        = CGRect(x: 0, y: view.frame.height / 2, width: pickerWidth, height: pickerHeight)
            
            addChild(filterPicker)
            filterPicker.view.frame = initialFrame
            view.addSubview(filterPicker.view)
            filterPicker.beginAppearanceTransition(true, animated: true)
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 2, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.filterPicker.view.frame = frame
            }, completion: { isDone in
                self.filterPicker.endAppearanceTransition()
                self.filterPicker.didMove(toParent: self)
            })
        } else {
            present(filterPicker, animated: true, completion: nil)
        }
    }
    
    func picked(filterName: String) {
        switchToFilter(name: filterName)
        do {
            try setUserDefault(value: filterName, forKey: .activeFilter)
        } catch {
            os_log(.error, "Unexpected error when trying to save the active filter: %s", error.localizedDescription)
        }
        
        if !shouldUseCompactPicker {
            dismissPicker()
        }
    }
    
    func switchedCompactMode(to: Bool) {
        // 1. Change value in the variable
        // 2. Re-present the child controller
    }
    
    func dismissPicker() {
        // Animate and dismiss the controller
        if shouldUseCompactPicker {
            filterPicker.willMove(toParent: nil)
            filterPicker.view.removeFromSuperview()
            filterPicker.removeFromParent()
        } else {
            filterPicker.dismiss(animated: true, completion: nil)
        }
        
    }
}
