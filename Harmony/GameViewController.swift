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

class InputView: MTKView {
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
//  var   paused = true
//        enableSetNeedsDisplay = false

        Swift.print("init with coder")
    }
    
    override func keyUp(theEvent: NSEvent) {
        Swift.print("hello key up")
    }
    override func keyDown(theEvent: NSEvent) {
        Swift.print("hello key down")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

func GLKMatrix4ToUnsafePointer(matrix: GLKMatrix4) -> UnsafePointer<Float> {
    let a = Array(arrayLiteral: matrix.m)
    return UnsafePointer<Float>(a)
}

class GameViewController: NSViewController, MTKViewDelegate {
    
    var device: MTLDevice!
    
    var commandQueue: MTLCommandQueue!
    var defaultPipelineState: MTLRenderPipelineState!
    var blackAndWhitePipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var projectionMatrix: GLKMatrix4!

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
        let view = self.view as! MTKView
        view.delegate = self
        view.device = device
        view.sampleCount = 4
        view.becomeFirstResponder()
        
        loadAssets()
    }
    
    func loadAssets() {
        redTriangle = Triangle(device, name: "red", position: GLKVector3Make(0.5, 0.0, -0.5), color: GLKVector3Make(0.8, 0.1, 0.1))
        greenTriangle = Triangle(device, name: "green", position: GLKVector3Make(-0.5, 0.0, -1.0), color: GLKVector3Make(0.1, 0.8, 0.1))

        let defaultLibrary = device.newDefaultLibrary()!
        defaultPipelineState = createRenderingPipelineWithVertexShader("basic_vertex", fragmentShaderName: "basic_fragment", library: defaultLibrary)
        blackAndWhitePipelineState = createRenderingPipelineWithVertexShader("basic_vertex", fragmentShaderName: "bw_fragment", library: defaultLibrary)


        let fovyRadians: Float = Float(M_PI * 0.66)
        let aspectRatio: Float = Float(CGRectGetWidth(self.view.frame) / CGRectGetHeight(self.view.frame))
        let nearZ: Float = 0.1
        let farZ: Float = 100.0
        projectionMatrix = GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ)

        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
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
        let matrix = triangle.modelMatrix()
        let sizeOfMatrix4x4 = 16

        let sizeOfSingleMatrix = sizeof(Float) * sizeOfMatrix4x4
        let sizeOfUniformBuffer = sizeOfSingleMatrix * 2

        let uniformBuffer = device.newBufferWithLength(sizeOfUniformBuffer, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        let uniformContents = uniformBuffer.contents()
        memcpy(uniformContents, GLKMatrix4ToUnsafePointer(matrix), sizeOfSingleMatrix)
        memcpy(uniformContents + sizeOfSingleMatrix, GLKMatrix4ToUnsafePointer(self.projectionMatrix), sizeOfSingleMatrix)
        return uniformBuffer
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
