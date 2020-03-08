//
//  CameraController.swift
//  Color Camera
//
//  Created by Ted on 6/4/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

// MARK: Properties
class CameraManager {
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var currentCameraPosition: CameraPosition?
    var flashStatus: Bool?
    var photoOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
}

// MARK: Prepare
extension CameraManager {
    func prepare(captureVideoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = (session.devices.compactMap{ $0 })
            if cameras.isEmpty { throw CameraManagerError.noCamerasAvailable }
            
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraManagerError.captureSessionIsMissing }
            
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                self.currentCameraPosition = .rear
            }
            
            else if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                self.currentCameraPosition = .front
            }
            
            else { throw CameraManagerError.noCamerasAvailable }
            
        }
        
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraManagerError.captureSessionIsMissing }
            
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            
            captureSession.startRunning()
        }
        
        func configureVideoOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
            guard let captureSession = self.captureSession else { throw CameraManagerError.captureSessionIsMissing }
            
            self.videoOutput = AVCaptureVideoDataOutput()
            self.videoOutput!.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "Sample Buffer Queue"))
            
            if captureSession.canAddOutput(self.videoOutput!) { captureSession.addOutput(self.videoOutput!) }
            for connection in self.videoOutput!.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        DispatchQueue.init(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
                try configureVideoOutput(delegate: captureVideoDelegate)
            }
            
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
}

// MARK: Use the camera
extension CameraManager {
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraManagerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    func switchCamera() throws {
        guard let currentCameraPosition = currentCameraPosition, let captureSession = captureSession, captureSession.isRunning else { throw CameraManagerError.captureSessionIsMissing }
        
        func switchToFrontCamera() throws {
            guard let frontCamera = self.frontCamera else { throw CameraManagerError.invalidOperation}
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.removeInput(rearCameraInput!)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }
            else { throw CameraManagerError.invalidOperation }
        }
        func switchToRearCamera() throws {
            guard let rearCamera = self.rearCamera else { throw CameraManagerError.invalidOperation}
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            captureSession.removeInput(frontCameraInput!)
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.currentCameraPosition = .rear
            }
            else { throw CameraManagerError.invalidOperation }
        }
        
        captureSession.beginConfiguration()
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
        case .rear:
            try switchToFrontCamera()
        }
        for connection in self.videoOutput!.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        captureSession.commitConfiguration()
    }
    
    func toggleFlash() throws {
        guard let device = AVCaptureDevice.default(for: .video) else { throw CameraManagerError.invalidOperation }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    try device.setTorchModeOn(level: 1.0)
                    self.flashStatus = true
                } else {
                    device.torchMode = .off
                    self.flashStatus = false
                }
                device.unlockForConfiguration()
            }
            catch {
                print(error)
            }
        }
    }
}

extension CameraManager {
    public enum CameraPosition {
        case front
        case rear
    }
    
    enum CameraManagerError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
}
