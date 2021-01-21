//
//  ProcessableGraphicsShader.metal
//  YuruImageProcessor
//
//  Created by クワシマ・ユウキ on 2021/01/21.
//

#include <metal_stdlib>
using namespace metal;

struct Pixel {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
};

kernel void RGBtoBGR (const device Pixel* inputData [[ buffer(0)]],
                          device Pixel* outputData [[ buffer(1)]],
                          uint thread_position_in_grid [[thread_position_in_grid]]) {
    
    uint8_t tempR = inputData[thread_position_in_grid].r;
    outputData[thread_position_in_grid].r = inputData[thread_position_in_grid].b;
    outputData[thread_position_in_grid].b = tempR;
    outputData[thread_position_in_grid].g = inputData[thread_position_in_grid].g;
    outputData[thread_position_in_grid].a = inputData[thread_position_in_grid].a;
}

kernel void GrayScale (const device Pixel* inputData [[ buffer(0)]],
                          device Pixel* outputData [[ buffer(1)]],
                          uint thread_position_in_grid [[thread_position_in_grid]]) {
    uint8_t gray = inputData[thread_position_in_grid].r * 0.2126 + inputData[thread_position_in_grid].g * 0.7152 + inputData[thread_position_in_grid].b * 0.0722;
    outputData[thread_position_in_grid].r = gray;
    outputData[thread_position_in_grid].g = gray;
    outputData[thread_position_in_grid].b = gray;
    outputData[thread_position_in_grid].a = gray;
}

kernel void Binarize (const device Pixel* inputData [[ buffer(0)]],
                          device Pixel* outputData [[ buffer(1)]],
                          const device uint8_t* optionData [[buffer(2)]],
                          uint thread_position_in_grid [[thread_position_in_grid]]) {
    uint8_t gray = inputData[thread_position_in_grid].r * 0.2126 + inputData[thread_position_in_grid].g * 0.7152 + inputData[thread_position_in_grid].b * 0.0722;
    if (gray < optionData[0]) {
        outputData[thread_position_in_grid].r = 0;
        outputData[thread_position_in_grid].g = 0;
        outputData[thread_position_in_grid].b = 0;
        outputData[thread_position_in_grid].a = 0;
    } else {
        outputData[thread_position_in_grid].r = 255;
        outputData[thread_position_in_grid].g = 255;
        outputData[thread_position_in_grid].b = 255;
        outputData[thread_position_in_grid].a = 255;
    }
}

// Gray Scaled Data is necessary
kernel void OtsuBinarize (const device Pixel* inputData [[ buffer(0)]],
                          device Pixel* outputData [[ buffer(1)]],
                          uint thread_position_in_grid [[thread_position_in_grid]]) {
    uint8_t gray = inputData[thread_position_in_grid].r * 0.2126 + inputData[thread_position_in_grid].g * 0.7152 + inputData[thread_position_in_grid].b * 0.0722;
    
}



