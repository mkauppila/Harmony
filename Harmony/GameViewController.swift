//
//  GameViewController.swift
//  Harmony
//
//  Created by Markus Kauppila on 18/06/16.
//  Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

import Cocoa
import MetalKit

class InputView: MTKView {
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
//        paused = true
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

class GameViewController: NSViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    
    var triangle: Triangle?
    
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
        triangle = Triangle(device)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("basic_fragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("basic_vertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
    }
    
    func drawInMTKView(view: MTKView) {
        
        let metalView = self.view as! MTKView
        let drawable = metalView.currentDrawable!
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        
        let commandBuffer = commandQueue.commandBuffer()
        
        let renderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderCommandEncoder.setRenderPipelineState(pipelineState)
        
        renderCommandEncoder.setVertexBuffer(triangle!.vertexBuffer, offset: 0, atIndex: 0)
        renderCommandEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: triangle!.vertexCount, instanceCount: 1)
//        renderCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: 100, height: 600, znear: 0.0, zfar: 1.0))
        renderCommandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
