//
//  Renderer.swift
//  Harmony
//
//  Created by Markus Kauppila on 29/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation
import MetalKit
import GLKit

class Renderer {
    fileprivate(set) var device: MTLDevice!

    fileprivate var commandQueue: MTLCommandQueue!
    fileprivate var defaultPipelineState: MTLRenderPipelineState!
    fileprivate var blackAndWhitePipelineState: MTLRenderPipelineState!

    fileprivate var projectionMatrix: GLKMatrix4!
    fileprivate var cameraMatrix: GLKMatrix4!

    fileprivate let windowSize: CGSize
    fileprivate let componentStore: ComponentStore

    let sampleCount: Int = 4

    init(windowSize: CGSize, componentStore: ComponentStore) {
        self.windowSize = windowSize
        self.componentStore = componentStore

        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }

        let defaultLibrary = device.newDefaultLibrary()!
        defaultPipelineState = createRenderingPipelineWithVertexShader("basic_vertex",
                                                                       fragmentShaderName: "basic_fragment",
                                                                       library: defaultLibrary)
        blackAndWhitePipelineState = createRenderingPipelineWithVertexShader("basic_vertex",
                                                                             fragmentShaderName: "bw_fragment",
                                                                             library: defaultLibrary)

        projectionMatrix = createProjectionMatrix()
        cameraMatrix = createCameraMatrix()

        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"
    }

    fileprivate func createProjectionMatrix() -> GLKMatrix4 {
        let fovyRadians: Float = Float(M_PI * 0.66)
        let aspectRatio: Float = Float(windowSize.width / windowSize.height)
        let nearZ: Float = 0.01
        let farZ: Float = 100.0
        return GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ)
    }

    fileprivate func createViewPort() -> MTLViewport {
        return MTLViewport(originX: 0.0,
                           originY: 0.0,
                           width: Double(windowSize.width) * 2,
                           height: Double(windowSize.height) * 2,
                           znear: 0.01,
                           zfar: 100.0)
    }

    fileprivate func createCameraMatrix() -> GLKMatrix4 {
        return GLKMatrix4New()
    }

    fileprivate func createRenderingPipelineWithVertexShader(_ vertexShaderName: String,
                                                         fragmentShaderName: String,
                                                         library: MTLLibrary) -> MTLRenderPipelineState? {
        let vertexProgram = library.makeFunction(name: vertexShaderName)!
        let fragmentProgram = library.makeFunction(name: fragmentShaderName)!

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm

        do {
            let newPipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            return newPipelineState
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
            return nil
        }
    }

    func drawRenderables(_ drawable: CAMetalDrawable, allRenderables: [Renderable]) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let commandBuffer = commandQueue.makeCommandBuffer()

        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCommandEncoder.setViewport(createViewPort())

        for renderable in allRenderables  {
            renderRenderable(renderable,
                             renderPipelineState: defaultPipelineState,
                             renderCommandEncoder: renderCommandEncoder)
        }

        renderCommandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    fileprivate func renderRenderable(_ renderable: Renderable,
                                  renderPipelineState: MTLRenderPipelineState,
                                  renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(renderable.vertexBuffer, offset: 0, at: 0)

        if let transform: Transform = componentStore.findComponent(Transform.self, forObjectId: renderable.objectId) {
            renderCommandEncoder.setVertexBuffer(createUniforms(transform.modelMatrix()), offset: 0, at: 1)
        }

        renderCommandEncoder.drawPrimitives(type: .line,
                                            vertexStart: 0,
                                            vertexCount: renderable.vertexCount,
                                            instanceCount: 1)
    }

    fileprivate func createUniforms(_ modelMatrix: GLKMatrix4) -> MTLBuffer {
        let transformedModelMatrix = GLKMatrix4Multiply(cameraMatrix, modelMatrix)

        let sizeOfMatrix4x4 = 16
        let sizeOfSingleMatrixInBytes = MemoryLayout<Float>.size * sizeOfMatrix4x4
        let sizeOfUniformBufferInBytes = sizeOfSingleMatrixInBytes * 2

        let uniformBuffer = device.makeBuffer(length: sizeOfUniformBufferInBytes,
                                                       options: MTLResourceOptions())
        let uniformContents = uniformBuffer.contents()
        memcpy(uniformContents,
               GLKMatrix4ToUnsafePointer(transformedModelMatrix),
               sizeOfSingleMatrixInBytes)
        memcpy(uniformContents + sizeOfSingleMatrixInBytes,
               GLKMatrix4ToUnsafePointer(self.projectionMatrix),
               sizeOfSingleMatrixInBytes)
        return uniformBuffer
    }
}
