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
    /*
     {Normal:{ R:[100, 0, 0], G:[0, 100, 0], B:[0, 100, 0]},
     Protanopia:{ R:[56.667, 43.333, 0], G:[55.833, 44.167, 0], B:[0, 24.167, 75.833]},
     Protanomaly:{ R:[81.667, 18.333, 0], G:[33.333, 66.667, 0], B:[0, 12.5, 87.5]},
     Deuteranopia:{ R:[62.5, 37.5, 0], G:[70, 30, 0], B:[0, 30, 70]},
     Deuteranomaly:{ R:[80, 20, 0], G:[25.833, 74.167, 0], B:[0, 14.167, 85.833]},
     Tritanopia:{ R:[95, 5, 0], G:[0, 43.333, 56.667], B:[0, 47.5, 52.5]},
     Tritanomaly:{ R:[96.667, 3.333, 0], G:[0, 73.333, 26.667], B:[0, 18.333, 81.667]},
     Achromatopsia:{ R:[29.9, 58.7, 11.4], G:[29.9, 58.7, 11.4], B:[29.9, 58.7, 11.4]},
     Achromatomaly:{ R:[61.8, 32, 6.2], G:[16.3, 77.5, 6.2], B:[16.3, 32.0, 51.6]}
     */
    
    float4 protanopia(sample_t s) {
        // Protanopia:{ R:[56.667, 43.333, 0], G:[55.833, 44.167, 0], B:[0, 24.167, 75.833]},
        float r = s.r * 0.567 + s.g * 0.433 + s.b * 0;
        float g = s.r * 0.558 + s.g * 0.442 + s.b * 0;
        float b = s.r * 0 + s.g * 0.242 + s.b * 0.758;
        
        return float4(r, g, b, s.a);
    }
    
    float4 protanomaly(sample_t s) {
        // Protanomaly:{ R:[81.667, 18.333, 0], G:[33.333, 66.667, 0], B:[0, 12.5, 87.5]},
        float r = s.r * 0.817 + s.g * 0.183 + s.b * 0;
        float g = s.r * 0.333 + s.g * 0.667 + s.b * 0;
        float b = s.r * 0 + s.g * 0.125 + s.b * 0.875;
        
        return float4(r, g, b, s.a);
    }
    
    float4 deuteranopia(sample_t s) {
        // Deuteranopia:{ R:[62.5, 37.5, 0], G:[70, 30, 0], B:[0, 30, 70]},
        float r = s.r * 0.625 + s.g * 0.375 + s.b * 0;
        float g = s.r * 0.7 + s.g * 0.3 + s.b * 0;
        float b = s.r * 0 + s.g * 0.3 + s.b * 0.7;
        
        return float4(r, g, b, s.a);
    }
    
    float4 deuteranomaly(sample_t s) {
        // Deuteranomaly:{ R:[80, 20, 0], G:[25.833, 74.167, 0], B:[0, 14.167, 85.833]},
        float r = s.r * 0.8 + s.g * 0.2 + s.b * 0;
        float g = s.r * 0.258 + s.g * 0.742 + s.b * 0;
        float b = s.r * 0 + s.g * 0.142 + s.b * 0.858;
        
        return float4(r, g, b, s.a);
    }
    
    float4 tritanopia(sample_t s) {
        // Tritanopia:{ R:[95, 5, 0], G:[0, 43.333, 56.667], B:[0, 47.5, 52.5]},
        float r = s.r * 0.95 + s.g * 0.05 + s.b * 0;
        float g = s.r * 0.0 + s.g * 0.433 + s.b * 567;
        float b = s.r * 0 + s.g * 0.475 + s.b * 0.525;
        
        return float4(r, g, b, s.a);
    }
    
    float4 tritanomaly(sample_t s) {
        // Tritanomaly:{ R:[96.667, 3.333, 0], G:[0, 73.333, 26.667], B:[0, 18.333, 81.667]},
        float r = s.r * 0.967 + s.g * 0.033 + s.b * 0;
        float g = s.r * 0 + s.g * 0.733 + s.b * 0.267;
        float b = s.r * 0 + s.g * 0.183 + s.b * 0.817;
        
        return float4(r, g, b, s.a);
    }
    
    float4 tritanopia(sample_t s) {
        // Tritanopia:{ R:[95, 5, 0], G:[0, 43.333, 56.667], B:[0, 47.5, 52.5]},
        float r = s.r * 0.95 + s.g * 0.05 + s.b * 0;
        float g = s.r * 0.0 + s.g * 0.433 + s.b * 567;
        float b = s.r * 0 + s.g * 0.475 + s.b * 0.525;
        
        return float4(r, g, b, s.a);
    }
    
    float4 tritanomaly(sample_t s) {
        // Tritanomaly:{ R:[96.667, 3.333, 0], G:[0, 73.333, 26.667], B:[0, 18.333, 81.667]},
        float r = s.r * 0.967 + s.g * 0.033 + s.b * 0;
        float g = s.r * 0 + s.g * 0.733 + s.b * 0.267;
        float b = s.r * 0 + s.g * 0.183 + s.b * 0.817;
        
        return float4(r, g, b, s.a);
    }
}}
