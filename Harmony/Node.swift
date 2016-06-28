//
//  Node.swift
//  Harmony
//
//  Created by Markus Kauppila on 19/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import MetalKit
import GLKit

class Node {
    let name: String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer
    var device: MTLDevice
    
    init(name: String, vertices: [Vertex], device: MTLDevice) {
        var vertexData = [Float]()
        for vertex in vertices {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
        self.name = name
        self.device = device
        vertexCount = vertices.count
    }
}


//let vertexData:[Float] =
//    [
//        -0.2, -0.2, 0.0,
//        0.0, 0.0, 0.0,
//        0.2, -0.2, 0.0
//]
//
//let colorData: [Float] = [
//    1.0, 1.0, 1.0,
//    1.0, 1.0, 1.0,
//    1.0, 1.0, 1.0
//]


class Triangle: Node {
    init(_ device: MTLDevice) {
        let V0 = Vertex(position: GLKVector3Make(-0.2, -0.2, 0.0),   color: GLKVector4Make(1.0, 0.0, 0.0, 1.0))
        let V1 = Vertex(position: GLKVector3Make( 0.0,  0.0, 0.0),   color: GLKVector4Make(0.0, 1.0, 0.0, 1.0))
        let V2 = Vertex(position: GLKVector3Make( 0.2,  -0.2, 0.0),  color: GLKVector4Make(1.0, 0.0, 1.0, 1.0))
        super.init(name: "Triangle", vertices: [V0, V1, V2], device: device)
    }
}
