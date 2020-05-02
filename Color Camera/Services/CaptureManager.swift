//
//  CaptureManager.swift
//  Color Camera
//
//  Created by Ted on 4/5/20.
//  Copyright © 2020 Ted Kostylev. All rights reserved.

import Foundation
import AVFoundation


class CaptureManager: NSObject, AVCapturePhotoCaptureDelegate {
    typealias Action = () -> Void
    
    var willBeginCaptureCallback: Action
    var willCaptureCallback: Action
    var didCaptureCallback: Action
    var didFinishCaptureCallback: Action
    var didFinishProcessing: Action
    
    required init(willBeginCapture: @escaping Action,
                  willCapture: @escaping Action,
                  didCapture: @escaping Action,
                  didFinishCapture: @escaping Action,
                  didFinishProcessing: @escaping Action) {
        self.willBeginCaptureCallback = willBeginCapture
        self.willCaptureCallback = willCapture
        self.didCaptureCallback = didCapture
        self.didFinishCaptureCallback = didFinishCapture
        self.didFinishProcessing = didFinishProcessing
    }
    
    // MARK: Capture progress
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.willBeginCaptureCallback()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.willCaptureCallback()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.didCaptureCallback()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if error == nil {
            self.didFinishProcessing()
        } else {
            print("Failed to capture photo: \(error!)")
        }
    }
    
    // MARK: Receiving results
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            print("\(photo.description)")
            self.didFinishProcessing()
        } else {
            print("Failed to process photo: \(error!)")
        }
    }
}
