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

    override func viewDidLoad() {
        super.viewDidLoad()

        store = ComponentStore()
        renderer = Renderer(windowSize: self.view.frame.size, componentStore: store)

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

        if let transform: Transform = store.findComponentForObjectId(playerObjectId) {
            switch keyCode {
            case .A, .LeftArrow:
                transform.position = GLKVector3Add(transform.position, GLKVector3Make(0.1, 0.0, 0.0))
            case .D, .RightArrow:
                transform.position = GLKVector3Add(transform.position, GLKVector3Make(-0.1, 0.0, 0.0))
            case .W, .UpArrow:
                transform.position = GLKVector3Add(transform.position, GLKVector3Make(0.0, 0.0, -0.01))
            case .S, .DownArrow:
                transform.position = GLKVector3Add(transform.position, GLKVector3Make(0.0, 0.0, 0.01))
            default:
                break
            }

            print("position \(NSStringFromGLKVector3(transform.position))")
        }
    }
    
    func loadAssets() {
        let renderable = Renderable(objectId: playerObjectId,
                          vertexBuffer: createVertexBufferFrom(playerShipModel(), device: renderer.device),
                          vertexSizeInBytes: Vertex.sizeInBytes())
        let transform = Transform(objectId: playerObjectId, position: GLKVector3Make(0, 0.0, -0.5), angleInDegrees: 180);

        store.addComponentForObjectId(renderable, objectId: playerObjectId)
        store.addComponentForObjectId(transform, objectId: playerObjectId)
    }

    func drawInMTKView(view: MTKView) {
        let metalView = self.view as! MTKView
        let drawable = metalView.currentDrawable!

        let allRenderables: [Renderable] = store.allComponentsOfType()
        renderer.drawRenderables(drawable, allRenderables: allRenderables)
    }

    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
