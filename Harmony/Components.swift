//
//  Node.swift
//  Harmony
//
//  Created by Markus Kauppila on 19/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import MetalKit
import GLKit

typealias GameObjectId = Int

protocol Component {
    var objectId: GameObjectId { get }
}

class Renderable: Component {
    private (set) var objectId: GameObjectId

    let vertexBuffer: MTLBuffer
    let vertexCount: Int

    init(objectId: GameObjectId, vertexBuffer: MTLBuffer, vertexSizeInBytes: Int) {
        self.objectId = objectId
        self.vertexBuffer = vertexBuffer
        vertexCount = self.vertexBuffer.length / vertexSizeInBytes
    }
}

class Transform: Component {
    private (set) var objectId: GameObjectId

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
