//
//  Node.swift
//  Harmony
//
//  Created by Markus Kauppila on 19/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Metal
import GLKit

typealias GameObjectId = Int

protocol Component {
    var objectId: GameObjectId { get }
}

class LanePosition: Component {
    fileprivate (set) var objectId: GameObjectId
    var laneIndex: Int

    init(objectId: GameObjectId, laneIndex: Int) {
        self.objectId = objectId
        self.laneIndex = laneIndex
    }
}

class Renderable: Component {
    fileprivate (set) var objectId: GameObjectId

    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let primitiveType: MTLPrimitiveType
    let model: [Vertex]

    init(objectId: GameObjectId, model: [Vertex], vertexBuffer: MTLBuffer,
         vertexSizeInBytes: Int,  primitiveType: MTLPrimitiveType) {
        self.objectId = objectId
        self.model = model
        self.vertexBuffer = vertexBuffer
        self.primitiveType = primitiveType;
        vertexCount = self.vertexBuffer.length / vertexSizeInBytes
    }
}

class Transform: Component {
    fileprivate (set) var objectId: GameObjectId

    var position: GLKVector3
    let angleInDegrees: Float

    init(objectId: GameObjectId, position: GLKVector3, angleInDegrees: Float) {
        self.objectId = objectId
        self.position = position
        self.angleInDegrees = angleInDegrees
    }

    func modelMatrix() -> GLKMatrix4 {
        var matrix = GLKMatrix4New()
        matrix = GLKMatrix4Translate(matrix, position.x, position.y, position.z)
        matrix = GLKMatrix4RotateZ(matrix, GLKMathDegreesToRadians(angleInDegrees))
        return matrix
    }
}
