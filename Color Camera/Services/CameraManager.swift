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
    public enum CameraPosition {
        case front
        case rear
    }
    
    lazy var captureSession: AVCaptureSession = AVCaptureSession()
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    lazy var cameraPosition: CameraPosition = .rear
    lazy var isFlashOn: Bool = false
    lazy var photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    lazy var videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
}

// MARK: Prepare
extension CameraManager {
    func getCaptureDevices() throws {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        guard !session.devices.isEmpty else { fatalError("No cameras available on device") }
        
        self.frontCamera = session.devices.first(where: { $0.position == .front } )
        self.rearCamera  = session.devices.first(where: { $0.position == .back } )
        
        if let rear = self.rearCamera {
            try rear.lockForConfiguration()
            rear.focusMode = .continuousAutoFocus
            rear.unlockForConfiguration()
        }
    }
    
    func configureDeviceInputs(for session: AVCaptureSession) throws {
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            if session.canAddInput(self.rearCameraInput!) {
                session.addInput(self.rearCameraInput!)
                self.cameraPosition = .rear
            }
        }
        if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(self.frontCameraInput!) {
                session.addInput(self.frontCameraInput!)
                self.cameraPosition = .front
            }
        }
    }
    
    func configurePhotoOutput(for session: AVCaptureSession) {
        self.photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        if captureSession.canAddOutput(self.photoOutput) { captureSession.addOutput(self.photoOutput) }
        captureSession.startRunning()
    }
    
    func configureVideoOutput(for session: AVCaptureSession, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "Sample Buffer Queue"))
        
        if captureSession.canAddOutput(self.videoOutput) { captureSession.addOutput(self.videoOutput) }
        for connection in self.videoOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
    
    func prepare(captureVideoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue(label: "Prepare Camera Manager").async {
            do {
                try self.getCaptureDevices()
                try self.configureDeviceInputs(for: self.captureSession)
                self.configurePhotoOutput(for: self.captureSession)
                self.configureVideoOutput(for: self.captureSession, delegate: captureVideoDelegate)
            }
            catch {
                DispatchQueue.main.async { completionHandler(error) }
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
    func displayPreview(on view: UIView, aspectRatio: AVLayerVideoGravity) {
        guard self.captureSession.isRunning else { fatalError("Capture session not running") }
        self.previewLayer.videoGravity = aspectRatio
        self.previewLayer.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer, at: 0)
        self.previewLayer.frame = view.frame
    }
    
    func switchCameras() throws {
        guard self.captureSession.isRunning else { fatalError("Capture session not running") }
        self.captureSession.beginConfiguration()
        
        if (self.cameraPosition == .front) && (self.rearCamera != nil) {
            // Switch to rear
            let input = try AVCaptureDeviceInput(device: self.rearCamera!)
            if let otherInput = self.captureSession.inputs.first {
                self.captureSession.removeInput(otherInput)
            }
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.cameraPosition = .rear
            } else {
                print("Can't add input, session already has \(self.captureSession.inputs)")
            }
        } else if (self.cameraPosition == .rear) && (self.frontCamera != nil) {
            // Switch to front
            let input = try AVCaptureDeviceInput(device: self.frontCamera!)
            if let otherInput = self.captureSession.inputs.first {
                self.captureSession.removeInput(otherInput)
            }
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.cameraPosition = .front
            } else {
                print("Can't add input, session already has \(self.captureSession.inputs)")
            }
        } else {
            print("No other cameras available to switch away from \(self.cameraPosition)")
        }
        for connection in self.videoOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        captureSession.commitConfiguration()
    }
    
    func toggleFlash() throws {
        guard let device = AVCaptureDevice.default(for: .video) else { fatalError("No default device available for video") }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    try device.setTorchModeOn(level: 1.0)
                    self.isFlashOn = true
                } else {
                    device.torchMode = .off
                    self.isFlashOn = false
                }
                device.unlockForConfiguration()
            }
            catch {
                print(error)
            }
        }
    }
}
