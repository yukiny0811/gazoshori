//
//  ProcessableGraphicsShader.metal
//  YuruImageProcessor
//
//  Created by クワシマ・ユウキ on 2021/01/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void test_function (const device uint8_t* inputData [[ buffer(0)]],
                          device uint8_t* outputData [[ buffer(1)]],
                          uint thread_position_in_grid [[thread_position_in_grid]]) {
    
    outputData[thread_position_in_grid] = inputData[thread_position_in_grid];
}
