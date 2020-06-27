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
import os.log

class CameraManager {
    // MARK: Properties
    public enum CameraPosition: String {
        case front = "front"
        case rear  = "rear"
    }
    
    let captureSession: AVCaptureSession = AVCaptureSession()
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var cameraPosition: CameraPosition = .rear
    var isFlashOn: Bool = false
    var cameraPhotoOutput: AVCapturePhotoOutput!
    var videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())

    // MARK: Prepare
    static func checkPermissions() throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                return
            
            case .notDetermined: // The user has not yet been asked for camera access.
                var shouldThrow: Bool = true
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        return
                    } else {
                        shouldThrow = true
                        return
                    }
                }
                if shouldThrow {
                    throw CameraManagerError.notAuthorized
            }
            
            case .denied: // The user has previously denied access.
                throw CameraManagerError.notAuthorized

            case .restricted: // The user can't grant access due to restrictions.
                throw CameraManagerError.notAuthorized
        
        @unknown default:
            throw CameraManagerError.unknown
        }
    }
    
    func getCaptureDevices() throws {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        guard !session.devices.isEmpty else { throw CameraManagerError.noDevicesAvailable }
        
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
        self.cameraPhotoOutput = AVCapturePhotoOutput()
        self.cameraPhotoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        if captureSession.canAddOutput(self.cameraPhotoOutput) {
            captureSession.addOutput(self.cameraPhotoOutput)
            
            cameraPhotoOutput.isHighResolutionCaptureEnabled = true
            cameraPhotoOutput.isLivePhotoCaptureEnabled = cameraPhotoOutput.isLivePhotoCaptureSupported
            cameraPhotoOutput.isDepthDataDeliveryEnabled = cameraPhotoOutput.isDepthDataDeliverySupported
            cameraPhotoOutput.isPortraitEffectsMatteDeliveryEnabled = cameraPhotoOutput.isPortraitEffectsMatteDeliverySupported
            cameraPhotoOutput.enabledSemanticSegmentationMatteTypes = cameraPhotoOutput.availableSemanticSegmentationMatteTypes
            cameraPhotoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            os_log(.error, "Failed to add photo output!")
        }
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
        do {
            try CameraManager.checkPermissions()
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            try self.getCaptureDevices()
            try self.configureDeviceInputs(for: self.captureSession)
            self.configurePhotoOutput(for: self.captureSession)
            self.configureVideoOutput(for: self.captureSession, delegate: captureVideoDelegate)
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
        catch {
            completionHandler(error)
            return
        }
        completionHandler(nil)
    }

    // MARK: Use the camera
    func switchCameras() throws {
        guard self.captureSession.isRunning else { throw CameraManagerError.sessionNotRunning }
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
                os_log(.error, "Can't add input, session already has %s", self.captureSession.inputs.description)
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
                os_log(.error, "Can't add input, session already has %s", self.captureSession.inputs.description)
            }
        } else {
            os_log(.error, "No other cameras available to switch away from %s", self.cameraPosition.rawValue)
        }
        for connection in self.videoOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        captureSession.commitConfiguration()
    }
    
    func toggleFlash() throws {
        guard let device = AVCaptureDevice.default(for: .video) else { throw CameraManagerError.noVideoDevice }
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
                os_log(.error, "%s", error.localizedDescription)
            }
        }
    }
}

enum CameraManagerError: Error {
    case unknown
    case notAuthorized
    case noDevicesAvailable
    case sessionNotRunning
    case noVideoDevice
}
