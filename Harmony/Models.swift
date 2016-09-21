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
    return [
        Vertex(position: GLKVector3Make(-0.2, -0.2, 0),   color: GLKVector4MakeWithVector3(color, 1.0)),
        Vertex(position: GLKVector3Make( 0.0,  0.0, 0),   color: GLKVector4MakeWithVector3(color, 1.0)),
        Vertex(position: GLKVector3Make( 0.2,  -0.2, 0),  color: GLKVector4MakeWithVector3(color, 1.0))
    ]
}

func levelModel() -> [Vertex]  {
    let red = GLKVector4Make(1.0, 0.0, 0.0, 1.0)
    let green = GLKVector4Make(0.0, 1.0, 0.0, 1.0)
    let blue = GLKVector4Make(0.0, 0.0, 1.0, 1.0)
    let purple = GLKVector4Make(1.0, 0.0, 1.0, 1.0)

    // For drawing the model as .Lines
    return [
        Vertex(position: GLKVector3Make(-1.0, 3.0, 0.0), color: purple),
        Vertex(position: GLKVector3Make(1.0, 3.0, 0.0),  color: green),

        Vertex(position: GLKVector3Make(1.0, 3.0, 0.0),  color: green),
        Vertex(position: GLKVector3Make(1.0, 1.0, 0.0),  color: blue),

        Vertex(position: GLKVector3Make(1.0, 1.0, 0.0),  color: blue),
        Vertex(position: GLKVector3Make(3.0, 1.0, 0.0),  color: red),

        Vertex(position: GLKVector3Make(3.0, 1.0, 0.0),  color: red),
        Vertex(position: GLKVector3Make(3.0, -1.0, 0.0),  color: green),

        Vertex(position: GLKVector3Make(3.0, -1.0, 0.0),  color: green),
        Vertex(position: GLKVector3Make(1.0, -1.0, 0.0),  color: blue),

        Vertex(position: GLKVector3Make(1.0, -1.0, 0.0),  color: blue),
        Vertex(position: GLKVector3Make(1.0, -3.0, 0.0),  color: red),

        Vertex(position: GLKVector3Make(1.0, -3.0, 0.0),  color: red),
        Vertex(position: GLKVector3Make(-1.0, -3.0, 0.0),  color: green),

        Vertex(position: GLKVector3Make(-1.0, -3.0, 0.0),  color: green),
        Vertex(position: GLKVector3Make(-1.0, -1.0, 0.0),  color: blue),

        Vertex(position: GLKVector3Make(-1.0, -1.0, 0.0),  color: blue),
        Vertex(position: GLKVector3Make(-3.0, -1.0, 0.0),  color: red),

        Vertex(position: GLKVector3Make(-3.0, -1.0, 0.0),  color: red),
        Vertex(position: GLKVector3Make(-3.0, 1.0, 0.0),  color: green),

        Vertex(position: GLKVector3Make(-3.0, 1.0, 0.0),  color: green),
        Vertex(position: GLKVector3Make(-1.0, 1.0, 0.0),  color: blue),

        Vertex(position: GLKVector3Make(-1.0, 1.0, 0.0),  color: blue),
        Vertex(position: GLKVector3Make(-1.0, 3.0, 0.0),  color: purple),
    ];

//    Line strip
//    return [
//        Vertex(position: GLKVector3Make(-1.0, 3.0, 0.0), color: purple),
//        Vertex(position: GLKVector3Make(1.0, 3.0, 0.0),  color: green),
//        Vertex(position: GLKVector3Make(1.0, 1.0, 0.0),  color: blue),
//        Vertex(position: GLKVector3Make(3.0, 1.0, 0.0),  color: red),
//        Vertex(position: GLKVector3Make(3.0, -1.0, 0.0),  color: green),
//        Vertex(position: GLKVector3Make(1.0, -1.0, 0.0),  color: blue),
//        Vertex(position: GLKVector3Make(1.0, -3.0, 0.0),  color: red),
//        Vertex(position: GLKVector3Make(-1.0, -3.0, 0.0),  color: green),
//        Vertex(position: GLKVector3Make(-1.0, -1.0, 0.0),  color: blue),
//        Vertex(position: GLKVector3Make(-3.0, -1.0, 0.0),  color: red),
//        Vertex(position: GLKVector3Make(-3.0, 1.0, 0.0),  color: green),
//        Vertex(position: GLKVector3Make(-1.0, 1.0, 0.0),  color: blue),
//        Vertex(position: GLKVector3Make(-1.0, 3.0, 0.0),  color: purple),
//    ];
}

func createVertexBufferFrom(_ vertices: [Vertex], device: MTLDevice) -> MTLBuffer {
    var vertexData = [Float]()
    for vertex in vertices {
        vertexData += vertex.floatBuffer()
    }

    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    let vertexBuffer = device.makeBuffer(bytes: vertexData,
            length: dataSize,
            options: MTLResourceOptions())

    return vertexBuffer
}
