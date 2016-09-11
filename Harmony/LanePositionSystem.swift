//
// Created by Markus Kauppila on 11/09/16.
// Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

import Cocoa
import MetaKit
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

//        let transform: Transform = store.findComponent(Transform.self, forObjectId: moverId)!
//        let lanePosition: LanePosition = store.findComponent(LanePosition.self, forObjectId: moverId)!
//
//        let levelRenderable: Renderable = store.findComponent(Renderable.self, forObjectId: levelId)!
//        let levelTransform: Transform = store.findComponent(Transform.self, forObjectId: levelId)!
//
//        switch (action) {
//        case .MoveLeft:
//            lanePosition.laneIndex -= 1
//        case .MoveRight:
//            lanePosition.laneIndex += 1
//        }
//
//        let maximumLaneIndex = levelRenderable.model.count / 2
//        if lanePosition.laneIndex < 0 {
//            lanePosition.laneIndex = maximumLaneIndex
//        } else if lanePosition.laneIndex > maximumLaneIndex {
//            lanePosition.laneIndex = 0
//        }

        let lanePosition2: LanePosition = store.findComponent(LanePosition.self, forObjectId: moverId)!
        let levelRenderable: Renderable = store.findComponent(Renderable.self, forObjectId: levelId)!
        let transform: Transform = store.findComponent(Transform.self, forObjectId: moverId)!
        let levelTransform: Transform = store.findComponent(Transform.self, forObjectId: levelId)!

        let lanePosition = updateLanePosition(action, lanePosition: lanePosition2, levelRenderable: levelRenderable)

        print("Lane index \(lanePosition.laneIndex)")

        // Find out the line points for the lane
        let firstIndex =  2 * lanePosition.laneIndex
        let secondIndex =  2 * lanePosition.laneIndex + 1
        if secondIndex > levelRenderable.model.count {
            print("Error: Lane position index overflow for position \(lanePosition.laneIndex)")
            return
        }

        let firstVertex = levelRenderable.model[firstIndex]
        let secondVertex = levelRenderable.model[secondIndex]

        print("First vertex \(NSStringFromGLKVector3(firstVertex.position))")
        print("Second vertex \(NSStringFromGLKVector3(secondVertex.position))")


        let vec1 = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), firstVertex.position)
        let vec2 = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), secondVertex.position)
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

        transform.position = GLKVector3Make(x, y, -3.5)

        print("position \(NSStringFromGLKVector3(transform.position))")
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


    private func angleBetweenVectorsInDegrees(lhs: GLKVector3, rhs: GLKVector3) -> Float {
        let deltaX = lhs.x - rhs.x
        let deltaY = lhs.y - rhs.y
        let angleInRadians = atan2(deltaX, deltaY)
        return GLKMathRadiansToDegrees(angleInRadians)
    }
}