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

protocol KeyboardInputDelegate {
    func keyUp(event: NSEvent)
    func keyDown(event: NSEvent)
}

class InputView: MTKView {
    var inputDelegate: KeyboardInputDelegate?

    required init(coder: NSCoder) {
        super.init(coder: coder)
        
//  var   paused = true
//        enableSetNeedsDisplay = false

        Swift.print("init with coder")
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

func GLKMatrix4ToUnsafePointer(matrix: GLKMatrix4) -> UnsafePointer<Float> {
    let a = Array(arrayLiteral: matrix.m)
    return UnsafePointer<Float>(a)
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
}

class GameViewController: NSViewController, MTKViewDelegate, KeyboardInputDelegate {
    
    var device: MTLDevice!
    
    var commandQueue: MTLCommandQueue!
    var defaultPipelineState: MTLRenderPipelineState!
    var blackAndWhitePipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!

    var projectionMatrix: GLKMatrix4!
    var worldMatrix: GLKMatrix4!

    var redTriangle: Triangle!
    var greenTriangle: Triangle!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }

        // setup view properties
        let view = self.view as! InputView
        view.delegate = self
        view.device = device
        view.sampleCount = 4
        view.becomeFirstResponder()

        view.inputDelegate = self
        loadAssets()
    }

    override func keyUp(event: NSEvent) {
    }

    override func keyDown(event: NSEvent) {
        guard let keyCode = KeyCode(rawValue: event.keyCode) else {
            print("Not supported keyCode \(event.keyCode)")
            return;
        }

        switch keyCode {
        case .A:
            fallthrough
        case .LeftArrow:
            redTriangle.position = GLKVector3Add(redTriangle.position, GLKVector3Make(0.1, 0.0, 0.0))
        case .D:
            fallthrough
        case .RightArrow:
            redTriangle.position = GLKVector3Add(redTriangle.position, GLKVector3Make(-0.1, 0.0, 0.0))
        case .W:
            fallthrough
        case .UpArrow:
            redTriangle.position = GLKVector3Add(redTriangle.position, GLKVector3Make(0.0, 0.0, -0.01))
        case .S:
            fallthrough
        case .DownArrow:
            redTriangle.position = GLKVector3Add(redTriangle.position, GLKVector3Make(0.0, 0.0, 0.01))
        default:
            print("nothing")
        }

        print("model matrix \(NSStringFromGLKVector3(redTriangle.position))")
    }
    
    func loadAssets() {
        redTriangle = Triangle(device, name: "red", position: GLKVector3Make(0.5, 0.0, -0.5), color: GLKVector3Make(0.8, 0.1, 0.1))
        greenTriangle = Triangle(device, name: "green", position: GLKVector3Make(-0.5, 0.0, -1.0), color: GLKVector3Make(0.1, 0.8, 0.1))

        let defaultLibrary = device.newDefaultLibrary()!
        defaultPipelineState = createRenderingPipelineWithVertexShader("basic_vertex", fragmentShaderName: "basic_fragment", library: defaultLibrary)
        blackAndWhitePipelineState = createRenderingPipelineWithVertexShader("basic_vertex", fragmentShaderName: "bw_fragment", library: defaultLibrary)

        projectionMatrix = createProjectionMatrix()
        worldMatrix = createWorldMatrix()

        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
    }

    func createProjectionMatrix() -> GLKMatrix4 {
        let fovyRadians: Float = Float(M_PI * 0.66)
        let aspectRatio: Float = Float(CGRectGetWidth(self.view.frame) / CGRectGetHeight(self.view.frame))
        let nearZ: Float = 0.1
        let farZ: Float = 100.0
        return GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ)
    }

    func createWorldMatrix() -> GLKMatrix4 {
        var matrix = GLKMatrix4New()
        matrix = GLKMatrix4RotateY(matrix, Float(-M_PI_2/10))
        return matrix;
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
        renderTriangle(redTriangle, renderPipelineState: defaultPipelineState, renderCommandEncoder: renderCommandEncoder)
        renderTriangle(greenTriangle, renderPipelineState: blackAndWhitePipelineState, renderCommandEncoder: renderCommandEncoder)
        renderCommandEncoder.endEncoding()

        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }

    func renderTriangle(triangle: Triangle, renderPipelineState: MTLRenderPipelineState, renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(triangle.vertexBuffer, offset: 0, atIndex: 0)
        renderCommandEncoder.setVertexBuffer(createUniformMatrixFor(triangle), offset: 0, atIndex: 1)
        renderCommandEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: triangle.vertexCount, instanceCount: 1)
    }

    func createUniformMatrixFor(triangle: Triangle) -> MTLBuffer {
        let modelMatrix = triangle.modelMatrix()
        let transformedModelMatrix = GLKMatrix4Multiply(worldMatrix, modelMatrix)

        let sizeOfMatrix4x4 = 16
        let sizeOfSingleMatrix = sizeof(Float) * sizeOfMatrix4x4
        let sizeOfUniformBuffer = sizeOfSingleMatrix * 2

        let uniformBuffer = device.newBufferWithLength(sizeOfUniformBuffer, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        let uniformContents = uniformBuffer.contents()
        memcpy(uniformContents, GLKMatrix4ToUnsafePointer(transformedModelMatrix), sizeOfSingleMatrix)
        memcpy(uniformContents + sizeOfSingleMatrix, GLKMatrix4ToUnsafePointer(self.projectionMatrix), sizeOfSingleMatrix)
        return uniformBuffer
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
