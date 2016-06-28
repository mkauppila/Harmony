//
//  Shaders.metal
//  Harmony
//
//  Created by Markus Kauppila on 18/06/16.
//  Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

fragment half4 basic_fragment() {
    return half4(1.0);
}

vertex float4 basic_vertex(const device packed_float3 *vertex_array [[ buffer(0) ]],
                           const device packed_float4 *color_array [[buffer(1)]],
                           unsigned int vid [[ vertex_id ]]) {
    return float4(vertex_array[vid], 1.0);
}

