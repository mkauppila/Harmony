//
//  Shaders.metal
//  Harmony
//
//  Created by Markus Kauppila on 18/06/16.
//  Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut basic_vertex(const device VertexIn *vertexArray [[ buffer(0) ]],
                              const device Uniforms *uniforms [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    VertexIn vertexIn = vertexArray[vid];
    VertexOut vertexOut = {
        .position = uniforms->projectionMatrix * uniforms->modelMatrix * float4(vertexIn.position, 1),
        .color = vertexIn.color
    };
    return vertexOut;
}

fragment float4 basic_fragment(const VertexOut vertexOut) {
    return vertexOut.color;
}

fragment float4 bw_fragment(const VertexOut vertexOut) {
    return float4(0.5, 0.5, 0.5, 1.0);
}


