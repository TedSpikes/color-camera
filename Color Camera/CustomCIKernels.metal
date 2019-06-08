//
//  CustomCIKernels.metal
//  Color Camera
//
//  Created by Fedor on 6/8/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" { namespace coreimage {
    float4 protanopia(sample_t s) {
        s.r = 0;
        
        return s;
    }
}}
