//
//  GameViewController.swift
//  Harmony
//
//  Created by Markus Kauppila on 18/06/16.
//  Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

import Cocoa
import MetalKit
import GLKit

let playerObjectId = 0
let levelObjectId = 1

enum KeyCode: UInt16 {
    case A = 0
    case D = 2
    case W = 13
    case S = 1
    case Q = 12
    case E = 14

    case UpArrow = 126
    case DownArrow = 125
    case LeftArrow = 123
    case RightArrow = 124
}

protocol KeyboardInputDelegate {
    func keyUp(event: NSEvent)
    func keyDown(event: NSEvent)
}

class GameView: MTKView {
    var inputDelegate: KeyboardInputDelegate?

    required init(coder: NSCoder) {
        super.init(coder: coder)
//      paused = true
//      enableSetNeedsDisplay = false
    }
    
    override func keyUp(theEvent: NSEvent) {
        inputDelegate?.keyUp(theEvent)
    }
    override func keyDown(theEvent: NSEvent) {
        inputDelegate?.keyDown(theEvent)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

class GameViewController: NSViewController, MTKViewDelegate, KeyboardInputDelegate {
    
    var store: ComponentStore!
    var renderer: Renderer!

    var lanePositionSystem: LanePositionSystem!

    override func viewDidLoad() {
        super.viewDidLoad()

        store = ComponentStore()
        store.registerComponent(Renderable.self)
        store.registerComponent(Transform.self)
        store.registerComponent(LanePosition.self)

        renderer = Renderer(windowSize: self.view.frame.size, componentStore: store)
        lanePositionSystem = LanePositionSystem(store: store)

        // setup view properties
        let view = self.view as! GameView
        view.delegate = self
        view.device = renderer.device
        view.sampleCount = renderer.sampleCount
        view.becomeFirstResponder()
        view.inputDelegate = self

        loadAssets()
    }

    override func keyUp(event: NSEvent) {
    }

    override func keyDown(event: NSEvent) {
        guard let keyCode = KeyCode(rawValue: event.keyCode) else {
            print("Not supported keyCode \(event.keyCode)")
            return
        }

        switch keyCode {
        case .A, .LeftArrow:
            lanePositionSystem.perform(playerObjectId, levelId: levelObjectId, action: LanePositionAction.MoveRight)
        case .D, .RightArrow:
            lanePositionSystem.perform(playerObjectId, levelId: levelObjectId, action: LanePositionAction.MoveLeft)
        default:
            break
        }
    }

    func loadAssets() {
        createPlayer()
        createLevel()
    }

    func createPlayer() {
        let renderable = Renderable(objectId: playerObjectId,
                model: playerShipModel(),
                vertexBuffer: createVertexBufferFrom(playerShipModel(), device: renderer.device),
                vertexSizeInBytes: Vertex.sizeInBytes(),
                primitiveType: MTLPrimitiveType.TriangleStrip)
        let transform = Transform(objectId: playerObjectId, position: GLKVector3Make(0.0, 0.0, -3.5), angleInDegrees: 180)
        let lanePosition = LanePosition(objectId: playerObjectId, laneIndex: 0)

        store.addComponent(renderable, forObjectId: playerObjectId)
        store.addComponent(transform, forObjectId: playerObjectId)
        store.addComponent(lanePosition, forObjectId: playerObjectId)
    }

    func createLevel() {
        let renderable = Renderable(objectId: levelObjectId,
                model: levelModel(),
                vertexBuffer: createVertexBufferFrom(levelModel(), device: renderer.device),
                vertexSizeInBytes: Vertex.sizeInBytes(),
                primitiveType: MTLPrimitiveType.Line)
        let transform = Transform(objectId: levelObjectId, position: GLKVector3Make(0.0, 0.0, -3.5), angleInDegrees: 180)

        store.addComponent(renderable, forObjectId: levelObjectId)
        store.addComponent(transform, forObjectId: levelObjectId)
    }

    func drawInMTKView(view: MTKView) {
        let metalView = self.view as! MTKView
        let drawable = metalView.currentDrawable!

        let allRenderables: [Renderable] = store.allComponentsOfType(Renderable.self)
        renderer.drawRenderables(drawable, allRenderables: allRenderables)
    }

    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}

/*
class LanePositionSystem {
    let store: ComponentStore

    init(store: ComponentStore) {
        self.store = store
    }

    func perform(moverId: GameObjectId, levelId: GameObjectId, action: LanePositionAction) {
        let lanePosition2: LanePosition = store.findComponent(LanePosition.self, forObjectId: moverId)!
        let levelRenderable: Renderable = store.findComponent(Renderable.self, forObjectId: levelId)!
        let transform: Transform = store.findComponent(Transform.self, forObjectId: moverId)!
        let levelTransform: Transform = store.findComponent(Transform.self, forObjectId: levelId)!

        let updatedLanePosition = updateLanePosition(action, lanePosition: lanePosition2, levelRenderable: levelRenderable)

        if let (firstVertex, secondVertex) = verticesForLanePosition(updatedLanePosition, levelRenderable: levelRenderable) {
            let transformedFirstVertex = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), firstVertex.position)
            let transformedSecondVertex = GLKMatrix4MultiplyVector3(levelTransform.modelMatrix(), secondVertex.position)
            transform.position = calculatePlayerPositionBetweenVertices(transformedFirstVertex,
                    secondVertex: transformedSecondVertex)
        } else {
            print("Error: failed to get vertices for lane \(updatedLanePosition.laneIndex)")
        }
    }


    private func verticesForLanePosition(lanePosition: LanePosition, levelRenderable: Renderable) -> (Vertex, Vertex)? {
        // Find out the line points for the lane
        let firstIndex =  2 * lanePosition.laneIndex
        let secondIndex =  2 * lanePosition.laneIndex + 1
        if secondIndex > levelRenderable.model.count {
            print("Error: Lane position index overflow for position \(lanePosition.laneIndex)")
            return nil
        }

        return (levelRenderable.model[firstIndex], levelRenderable.model[secondIndex])
    }

    private func calculatePlayerPositionBetweenVertices(firstVertex: GLKVector3, secondVertex: GLKVector3) -> GLKVector3 {
        let middlePointBetweenVertices = GLKVector3DivideScalar(GLKVector3Add(firstVertex, secondVertex), 2)
        let vectorBetweenVertices = GLKVector3Subtract(firstVertex, secondVertex)

        let perpendicularVector = GLKVector2MultiplyScalar(
                GLKVector2Normalize(GLKVector2Make(-vectorBetweenVertices.y, vectorBetweenVertices.x)),
                -0.1)

        return GLKVector3Make(
                middlePointBetweenVertices.x + perpendicularVector.x,
                middlePointBetweenVertices.y + perpendicularVector.y,
                3.5)
    }

    private func angleBetweenVectorsInDegrees(lhs: GLKVector3, rhs: GLKVector3) -> Float {
        let deltaX = lhs.x - rhs.x
        let deltaY = lhs.y - rhs.y
        let angleInRadians = atan2(deltaX, deltaY)
        return GLKMathRadiansToDegrees(angleInRadians)
    }
}
*/
