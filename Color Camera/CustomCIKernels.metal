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
    // God-awful hackjob
    float4 vision(sample_t s, float red_x, float red_y, float red_z,
                              float green_x, float green_y, float green_z,
                              float blue_x, float blue_y, float blue_z) {
        float r_new = s.r * red_x + s.g * red_y + s.b * red_z;
        float g_new = s.r * green_x + s.g * green_y + s.b * green_z;
        float b_new = s.r * blue_x + s.g * blue_y + s.b * blue_z;
        
        return float4(r_new, g_new, b_new, s.a);
    }
}}
