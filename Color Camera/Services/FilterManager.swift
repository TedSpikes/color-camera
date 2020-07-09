//
//  KernelController.swift
//  Color Camera
//
//  Created by Ted on 6/8/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import Foundation
import CoreImage
import UIKit


struct ColorVector {
    var r: Float
    var g: Float
    var b: Float
    
    init(_ red: Float, _ green: Float, _ blue: Float) {
        self.r = red
        self.g = green
        self.b = blue
    }
}
struct ColorMatrix {
    var name: String
    var redVector: ColorVector
    var greenVector: ColorVector
    var blueVector: ColorVector
    var description: String
}

class FilterManager {
    private let filterNames: [String] = [  // An _ordered_ list of filters
        "No filter",
        "Protanopia",
        "Protanomaly",
        "Deuteranopia",
        "Deuteranomaly",
        "Tritanopia",
        "Tritanomaly",
        "Achromatopsia",
        "Achromatomaly"
    ]
    
    private let colorMatrices: [String: ColorMatrix] = [
        "No filter":        ColorMatrix(name: "No filter",
                                     redVector: ColorVector(100.0, 0, 0),
                                     greenVector: ColorVector(0, 100.0, 0),
                                     blueVector: ColorVector(0, 0, 100.0),
                                     description: "As the camera sees it."),
        "Protanopia":    ColorMatrix(name: "Protanopia",
                                     redVector: ColorVector(56.667, 43.333, 0),
                                     greenVector: ColorVector(55.833, 44.167, 0),
                                     blueVector: ColorVector(0, 24.167, 75.833),
                                     description: "Full red-blindness."),
        "Protanomaly":   ColorMatrix(name: "Protanomaly",
                                     redVector: ColorVector(81.667, 18.333, 0),
                                     greenVector: ColorVector(33.333, 66.667, 0),
                                     blueVector: ColorVector(0, 12.5, 87.5),
                                     description: "Partial red-blindness."),
        "Deuteranopia":  ColorMatrix(name: "Deuteranopia",
                                     redVector: ColorVector(62.5, 37.5, 0),
                                     greenVector: ColorVector(70, 30, 0),
                                     blueVector: ColorVector(0, 30, 70),
                                     description: "Full green-blindness."),
        "Deuteranomaly": ColorMatrix(name: "Deuteranomaly",
                                     redVector: ColorVector(80, 20, 0),
                                     greenVector: ColorVector(25.833, 74.167, 0),
                                     blueVector: ColorVector(0, 14.167, 85.833),
                                     description: "Partial green-blindness, green sensitivity moves to red."),
        "Tritanopia":    ColorMatrix(name: "Tritanopia",
                                     redVector: ColorVector(95, 5, 0),
                                     greenVector: ColorVector(0, 43.333, 56.667),
                                     blueVector: ColorVector(0, 47.5, 52.5),
                                     description: "A rare lack of blue perception."),
        "Tritanomaly":   ColorMatrix(name: "Tritanomaly",
                                     redVector: ColorVector(96.667, 3.333, 0),
                                     greenVector: ColorVector(0, 73.333, 26.667),
                                     blueVector: ColorVector(0, 18.333, 81.667),
                                     description: "A lighter form of tritanopia."),
        "Achromatopsia": ColorMatrix(name: "Achromatopsia",
                                     redVector: ColorVector(29.9, 58.7, 11.4),
                                     greenVector: ColorVector(29.9, 58.7, 11.4),
                                     blueVector: ColorVector(29.9, 58.7, 11.4),
                                     description: "Total color blindness."),
        "Achromatomaly": ColorMatrix(name: "Achromatomaly",
                                     redVector: ColorVector(61.8, 32, 6.2),
                                     greenVector: ColorVector(16.3, 77.5, 6.2),
                                     blueVector: ColorVector(16.3, 32.0, 51.6),
                                     description: "A lighter, very rare form of achromatopsia.")
    ]
    
    func getColorMatrix(name: String) -> ColorMatrix? {
        return self.colorMatrices[name]
    }
    
    func getFilterNames() -> [String] {self.filterNames}
}

extension FilterManager: CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        guard let colorMatrix = self.getColorMatrix(name: name) else { return nil }
        return VisionFilter(colorMatrix)
    }
}


class VisionFilter: CIFilter {
    var kernel: CIKernel
    var matrix: ColorMatrix
    
    private func createCIKernel() -> CIColorKernel {
        guard
            let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
            let data = try? Data(contentsOf: url)
        else {
            fatalError("Unable to get metallib") // Justified fatalError
        }
        guard
            let kernel: CIColorKernel = try? CIColorKernel(functionName: "vision", fromMetalLibraryData: data)
        else {
            fatalError("Couldn't create kernel") // Justified fatalError
        }
        return kernel
    }
    
    init(_ matrix: ColorMatrix){
        self.kernel = CIColorKernel()
        self.matrix = matrix
        super.init()
        self.kernel = self.createCIKernel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.kernel = CIColorKernel()
        self.matrix = ColorMatrix(name: "",
                                  redVector: ColorVector(0, 0, 0),
                                  greenVector: ColorVector(0, 0, 0),
                                  blueVector: ColorVector(0, 0, 0),
                                  description: "")
        super.init(coder: aDecoder)
    }
    
    override class func registerName(_ name: String,
                                     constructor anObject: CIFilterConstructor,
                                     classAttributes attributes: [String : Any] = [:]) {
        CIFilter.registerName("Vision", constructor: FilterManager(), classAttributes: attributes)
    }
    
    @objc dynamic var inputImage: CIImage?
    override var outputImage: CIImage? {
        guard let input = inputImage else {
            return nil
        }
        let src = CISampler(image: input)
        let redVector = self.matrix.redVector
        let greenVector = self.matrix.greenVector
        let blueVector = self.matrix.blueVector
        return kernel.apply(extent: input.extent, roiCallback: {return $1},
                            arguments: [src, redVector.r,   redVector.g,   redVector.b,
                                             greenVector.r, greenVector.g, greenVector.b,
                                             blueVector.r,  blueVector.g,  blueVector.b]
        )
    }
}

/// Extend CGImage orientation, so I can brigde it to UIImage
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}
