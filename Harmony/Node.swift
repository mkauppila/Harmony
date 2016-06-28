//
//  Node.swift
//  Harmony
//
//  Created by Markus Kauppila on 19/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import MetalKit
import GLKit

func GLKMatrix4New() -> GLKMatrix4 {
    var matrix = GLKMatrix4()
    matrix = GLKMatrix4Identity
    return matrix
}

class Node {
    let name: String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer
    var device: MTLDevice

    let position: GLKVector3

    init(name: String, vertices: [Vertex], device: MTLDevice, position: GLKVector3) {
        var vertexData = [Float]()
        for vertex in vertices {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
        self.name = name
        self.device = device
        self.position = position
        
        vertexCount = vertices.count
    }

    func modelMatrix() -> GLKMatrix4 {
        var matrix = GLKMatrix4New()
        matrix = GLKMatrix4Translate(matrix, position.x, position.y, position.z)
        return matrix
    }
}

class Triangle: Node {
    init(_ device: MTLDevice, position: GLKVector3, color: GLKVector3) {
        let V0 = Vertex(position: GLKVector3Make(-0.2, -0.2, 0.0),   color: GLKVector4MakeWithVector3(color, 1.0))
        let V1 = Vertex(position: GLKVector3Make( 0.0,  0.0, 0.0),   color: GLKVector4MakeWithVector3(color, 1.0))
        let V2 = Vertex(position: GLKVector3Make( 0.2,  -0.2, 0.0),  color: GLKVector4MakeWithVector3(color, 1.0))
        super.init(name: "Triangle", vertices: [V0, V1, V2], device: device, position: position)
    }
}
