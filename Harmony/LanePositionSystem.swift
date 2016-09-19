//
// Created by Markus Kauppila on 11/09/16.
// Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

import Cocoa
import MetalKit
import GLKit

enum LanePositionAction {
    case MoveLeft
    case MoveRight
}

class LanePositionSystem {
    let store: ComponentStore

    init(store: ComponentStore) {
        self.store = store
    }

    func perform(moverId: GameObjectId, levelId: GameObjectId, action: LanePositionAction) {
        print("Lane position action: \(action)")

        let originalLanePosition: LanePosition = store.findComponent(LanePosition.self, forObjectId: moverId)!
        let levelRenderable: Renderable = store.findComponent(Renderable.self, forObjectId: levelId)!
        let transform: Transform = store.findComponent(Transform.self, forObjectId: moverId)!
        let levelTransform: Transform = store.findComponent(Transform.self, forObjectId: levelId)!

        let lanePosition = updateLanePosition(action, lanePosition: originalLanePosition, levelRenderable: levelRenderable)

        guard let (firstVertex, secondVertex) = verticesForLanePosition(lanePosition, levelRenderable: levelRenderable) else {
            print("meh")
            return
        }

        let transformedFirstVertex = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), firstVertex.position)
        let transformedSecondVertex = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), secondVertex.position)
        transform.position = calculatePlayerPositionBetweenVertices(transformedFirstVertex,
            secondVertex: transformedSecondVertex)
    }

    private func updateLanePosition(action: LanePositionAction, lanePosition: LanePosition, levelRenderable: Renderable) -> LanePosition {
        switch (action) {
        case .MoveLeft:
            lanePosition.laneIndex -= 1
        case .MoveRight:
            lanePosition.laneIndex += 1
        }

        let maximumLaneIndex = levelRenderable.model.count / 2
        if lanePosition.laneIndex < 0 {
            lanePosition.laneIndex = maximumLaneIndex
        } else if lanePosition.laneIndex > maximumLaneIndex {
            lanePosition.laneIndex = 0
        }

        return lanePosition
    }

    private func verticesForLanePosition(lanePosition: LanePosition, levelRenderable: Renderable) -> (Vertex, Vertex)? {
        let firstIndex =  2 * lanePosition.laneIndex
        let secondIndex =  2 * lanePosition.laneIndex + 1
        if secondIndex > levelRenderable.model.count {
            print("Error: Lane position index overflow for position \(lanePosition.laneIndex)")
            return nil
        }

        let firstVertex = levelRenderable.model[firstIndex]
        let secondVertex = levelRenderable.model[secondIndex]
        return (firstVertex, secondVertex)
    }

    private func calculatePlayerPositionBetweenVertices(firstVertex: GLKVector3, secondVertex: GLKVector3) -> GLKVector3 {
        let vec1 = firstVertex
        let vec2 = secondVertex

        let vec3 = GLKVector3Subtract(vec1, vec2)
        let middleVec = GLKVector3DivideScalar(GLKVector3Add(vec1, vec2), 2)

        print("First vertex \(NSStringFromGLKVector3(vec1))")
        print("Second vertex \(NSStringFromGLKVector3(vec2))")
        print("middle vertex \(NSStringFromGLKVector3(middleVec))")

        print("vec3 \(NSStringFromGLKVector3(vec3))")

        let perp = GLKVector2Make(-vec3.y, vec3.x)
        let normPerp = GLKVector2MultiplyScalar(GLKVector2Normalize(perp), -0.1)

        let x: Float = middleVec.x + normPerp.x
        let y: Float = middleVec.y + normPerp.y

        return GLKVector3Make(x, y, -3.5)
    }

//    private func angleBetweenVectorsInDegrees(lhs: GLKVector3, rhs: GLKVector3) -> Float {
//        let deltaX = lhs.x - rhs.x
//        let deltaY = lhs.y - rhs.y
//        let angleInRadians = atan2(deltaX, deltaY)
//        return GLKMathRadiansToDegrees(angleInRadians)
//    }
}