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
    
    var device: MTLDevice!
    
    var commandQueue: MTLCommandQueue!
    var defaultPipelineState: MTLRenderPipelineState!
    var blackAndWhitePipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!

    var projectionMatrix: GLKMatrix4!
    var cameraMatrix: GLKMatrix4!

    var store: ComponentStore!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }

        // setup view properties
        let view = self.view as! GameView
        view.delegate = self
        view.device = device
        view.sampleCount = 4
        view.becomeFirstResponder()

        view.inputDelegate = self

        store = ComponentStore()

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
                          vertexBuffer: createVertexBufferFrom(playerShipModel(), device: device),
                          vertexSizeInBytes: Vertex.sizeInBytes())
        let physical = Transform(objectId: playerObjectId, position: GLKVector3Make(0, 0.0, -0.5), angleInDegrees: 180);

        store.addComponentForObjectId(renderable, objectId: playerObjectId)
        store.addComponentForObjectId(physical, objectId: playerObjectId)


        let defaultLibrary = device.newDefaultLibrary()!
        defaultPipelineState = createRenderingPipelineWithVertexShader("basic_vertex",
                                                                       fragmentShaderName: "basic_fragment",
                                                                       library: defaultLibrary)
        blackAndWhitePipelineState = createRenderingPipelineWithVertexShader("basic_vertex",
                                                                             fragmentShaderName: "bw_fragment",
                                                                             library: defaultLibrary)

        projectionMatrix = createProjectionMatrix()
        cameraMatrix = createCameraMatrix()

        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
    }

    func createProjectionMatrix() -> GLKMatrix4 {
        let fovyRadians: Float = Float(M_PI * 0.66)
        let aspectRatio: Float = Float(CGRectGetWidth(self.view.frame) / CGRectGetHeight(self.view.frame))
        let nearZ: Float = 0.01
        let farZ: Float = 100.0
        return GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ)
    }

    func createViewPort() -> MTLViewport {
        return MTLViewport(originX: 0.0,
                           originY: 0.0,
                           width: Double(CGRectGetWidth(self.view.frame)) * 2,
                           height: Double(CGRectGetHeight(self.view.frame)) * 2,
                           znear: 0.01,
                           zfar: 100.0)
    }

    func createCameraMatrix() -> GLKMatrix4 {
        return GLKMatrix4New()
    }

    func createRenderingPipelineWithVertexShader(vertexShaderName: String, fragmentShaderName: String,  library: MTLLibrary) -> MTLRenderPipelineState? {
        let vertexProgram = library.newFunctionWithName(vertexShaderName)!
        let fragmentProgram = library.newFunctionWithName(fragmentShaderName)!

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm

        do {
            let newPipelineState = try device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
            return newPipelineState
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
            return nil
        }
    }

    func drawInMTKView(view: MTKView) {
        let metalView = self.view as! MTKView
        let drawable = metalView.currentDrawable!
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let commandBuffer = commandQueue.commandBuffer()

        let renderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderCommandEncoder.setViewport(createViewPort())

        let allRenderables: [Renderable] = store.allComponentsOfType()
        for renderable in allRenderables  {
            renderRenderable(renderable,
                             renderPipelineState: defaultPipelineState,
                             renderCommandEncoder: renderCommandEncoder)
        }

        renderCommandEncoder.endEncoding()

        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }

    func renderRenderable(renderable: Renderable, renderPipelineState: MTLRenderPipelineState, renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(renderable.vertexBuffer, offset: 0, atIndex: 0)

        if let transform: Transform = store.findComponentForObjectId(renderable.objectId) {
            renderCommandEncoder.setVertexBuffer(createUniformsFor(transform.modelMatrix()), offset: 0, atIndex: 1)
        }

        renderCommandEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: renderable.vertexCount, instanceCount: 1)
    }

    func createUniformsFor(modelMatrix: GLKMatrix4) -> MTLBuffer {
        let transformedModelMatrix = GLKMatrix4Multiply(cameraMatrix, modelMatrix)

        let sizeOfMatrix4x4 = 16
        let sizeOfSingleMatrixInBytes = sizeof(Float) * sizeOfMatrix4x4
        let sizeOfUniformBufferInBytes = sizeOfSingleMatrixInBytes * 2

        let uniformBuffer = device.newBufferWithLength(sizeOfUniformBufferInBytes,
                                                       options: MTLResourceOptions.CPUCacheModeDefaultCache)
        let uniformContents = uniformBuffer.contents()
        memcpy(uniformContents,
               GLKMatrix4ToUnsafePointer(transformedModelMatrix),
               sizeOfSingleMatrixInBytes)
        memcpy(uniformContents + sizeOfSingleMatrixInBytes,
               GLKMatrix4ToUnsafePointer(self.projectionMatrix),
               sizeOfSingleMatrixInBytes)
        return uniformBuffer
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
