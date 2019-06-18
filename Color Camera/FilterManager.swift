//
//  KernelController.swift
//  Color Camera
//
//  Created by Fedor on 6/8/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import Foundation
import CoreImage

class FilterManager: CIFilterConstructor {
    init() {}
    
    func colors(for filter: String) -> [[Float]]? {
        let filter_library: [String: [[Float]]] = [
            "Normal": [[100.0, 0, 0], [0, 100.0, 0], [0, 100.0, 0]],
            "Protanopia": [[56.667, 43.333, 0], [55.833, 44.167, 0], [0, 24.167, 75.833]],
            "Protanomaly": [[81.667, 18.333, 0], [33.333, 66.667, 0], [0, 12.5, 87.5]],
            "Deuteranopia": [[62.5, 37.5, 0], [70, 30, 0], [0, 30, 70]],
            "Deuteranomaly": [[80, 20, 0], [25.833, 74.167, 0], [0, 14.167, 85.833]],
            "Tritanopia": [[95, 5, 0], [0, 43.333, 56.667], [0, 47.5, 52.5]],
            "Tritanomaly": [[96.667, 3.333, 0], [0, 73.333, 26.667], [0, 18.333, 81.667]],
            "Achromatopsia": [[29.9, 58.7, 11.4], [29.9, 58.7, 11.4], [29.9, 58.7, 11.4]],
            "Achromatomaly": [[61.8, 32, 6.2], [16.3, 77.5, 6.2], [16.3, 32.0, 51.6]]
        ]
        
        return filter_library[filter]
    }
    
    func filter(withName name: String) -> CIFilter? {
        let filter = VisionFilter()
        if let colors = self.colors(for: name) {
            filter.colors = colors
        } else {
            return nil
        }
        return filter
    }
    
    class VisionFilter: CIFilter {
        var kernel: CIKernel?
        var colors: [[Float]]?
        
        override init() {
            super.init()
            
            guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
                let data = try? Data(contentsOf: url)
                else { fatalError("Unable to get metallib") }
            
            guard let kernel: CIColorKernel = try? CIColorKernel(functionName: "vision", fromMetalLibraryData: data)
                else { fatalError("Couldn't create kernel") }
            
            self.kernel = kernel
        }
        
        required init?(coder aDecoder: NSCoder) {
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
                fatalError("No input image!")
            }
            guard let colors = self.colors else {
                fatalError("Empty colors set!")
            }
            let src = CISampler(image: input)
            return self.kernel?.apply(extent: input.extent, roiCallback: {return $1},
                                      arguments: [src, colors[0][0], colors[0][1], colors[0][2],
                                                       colors[1][0], colors[1][1], colors[1][2],
                                                       colors[2][0], colors[2][1], colors[2][2]]
            )
        }
    }
}
