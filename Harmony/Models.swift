//
//  Models.swift
//  Harmony
//
//  Created by Markus Kauppila on 29/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation
import GLKit

func playerShipModel() -> [Vertex] {
    let color = GLKVector3Make(0.0, 1.0, 0.0)
    let V0 = Vertex(position: GLKVector3Make(-0.2, -0.2, -0.5),   color: GLKVector4MakeWithVector3(color, 1.0))
    let V1 = Vertex(position: GLKVector3Make( 0.0,  0.0, -0.5),   color: GLKVector4MakeWithVector3(color, 1.0))
    let V2 = Vertex(position: GLKVector3Make( 0.2,  -0.2, -0.5),  color: GLKVector4MakeWithVector3(color, 1.0))
    return [V0, V1, V2]
}

func createVertexBufferFrom(vertices: [Vertex], device: MTLDevice) -> MTLBuffer {
    var vertexData = [Float]()
    for vertex in vertices {
        vertexData += vertex.floatBuffer()
    }

    let dataSize = vertexData.count * sizeofValue(vertexData[0])
    let vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.OptionCPUCacheModeDefault)

    return vertexBuffer
}