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
    var protanopia: CIFilter?
    
    var protanopiaKernel: CIColorKernel?
    
    
    init() {
        }
    
    func filter(withName name: String) -> CIFilter? {
        switch name {
        case "Protanopia":
            return protanopiaFilter()
        default:
            return nil
        }
    }
    
    class protanopiaFilter: CIFilter {
        var protanopiaKernel: CIKernel?
        
        override var name: String {
            get {
                return "Protanopia"
            }
            set {}
        }
        
        override init() {
            super.init()
            guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
                let data = try? Data(contentsOf: url)
                else { fatalError("Unable to get metallib") }
            
            guard let protanopiaKernel: CIColorKernel = try? CIColorKernel(functionName: "protanopia", fromMetalLibraryData: data) else { fatalError("Couldn't create kernel \(self.name)") }
            self.protanopiaKernel = protanopiaKernel
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override class func registerName(_ name: String,
                                constructor anObject: CIFilterConstructor,
                                classAttributes attributes: [String : Any] = [:]) {
            CIFilter.registerName("Protanopia", constructor: FilterManager(), classAttributes: attributes)
        }
        
        // MARK: I/O
        @objc dynamic var inputImage: CIImage?
        override var outputImage: CIImage? {
            if let input = inputImage {
                let src = CISampler(image: input)
                return self.protanopiaKernel?.apply(extent: input.extent, roiCallback: {return $1}, arguments: [src])
            } else {
                return nil
            }
        }
    }
}
