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

        let transform: Transform = store.findComponent(Transform.self, forObjectId: moverId)!
        let lanePosition: LanePosition = store.findComponent(LanePosition.self, forObjectId: moverId)!

        let levelRenderable: Renderable = store.findComponent(Renderable.self, forObjectId: levelId)!
        let levelTransform: Transform = store.findComponent(Transform.self, forObjectId: levelId)!

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

    private func angleBetweenVectorsInDegrees(lhs: GLKVector3, rhs: GLKVector3) -> Float {
        let deltaX = lhs.x - rhs.x
        let deltaY = lhs.y - rhs.y
        let angleInRadians = atan2(deltaX, deltaY)
        return GLKMathRadiansToDegrees(angleInRadians)
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
