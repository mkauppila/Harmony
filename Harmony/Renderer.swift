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
    private(set) var device: MTLDevice!

    private var commandQueue: MTLCommandQueue!
    private var defaultPipelineState: MTLRenderPipelineState!
    private var blackAndWhitePipelineState: MTLRenderPipelineState!

    private var projectionMatrix: GLKMatrix4!
    private var cameraMatrix: GLKMatrix4!

    private let windowSize: CGSize
    private let componentStore: ComponentStore

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

        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
    }

    private func createProjectionMatrix() -> GLKMatrix4 {
        let fovyRadians: Float = Float(M_PI * 0.66)
        let aspectRatio: Float = Float(windowSize.width / windowSize.height)
        let nearZ: Float = 0.01
        let farZ: Float = 100.0
        return GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ)
    }

    private func createViewPort() -> MTLViewport {
        return MTLViewport(originX: 0.0,
                           originY: 0.0,
                           width: Double(windowSize.width) * 2,
                           height: Double(windowSize.height) * 2,
                           znear: 0.01,
                           zfar: 100.0)
    }

    private func createCameraMatrix() -> GLKMatrix4 {
        return GLKMatrix4New()
    }

    private func createRenderingPipelineWithVertexShader(vertexShaderName: String,
                                                         fragmentShaderName: String,
                                                         library: MTLLibrary) -> MTLRenderPipelineState? {
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

    func drawRenderables(drawable: CAMetalDrawable, allRenderables: [Renderable]) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let commandBuffer = commandQueue.commandBuffer()

        let renderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderCommandEncoder.setViewport(createViewPort())

        for renderable in allRenderables  {
            renderRenderable(renderable,
                             renderPipelineState: defaultPipelineState,
                             renderCommandEncoder: renderCommandEncoder)
        }

        renderCommandEncoder.endEncoding()

        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }

    private func renderRenderable(renderable: Renderable,
                                  renderPipelineState: MTLRenderPipelineState,
                                  renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(renderable.vertexBuffer, offset: 0, atIndex: 0)

        if let transform: Transform = componentStore.findComponent(Transform.self, forObjectId: renderable.objectId) {
            renderCommandEncoder.setVertexBuffer(createUniforms(transform.modelMatrix()), offset: 0, atIndex: 1)
        }

        renderCommandEncoder.drawPrimitives(.Line,
                                            vertexStart: 0,
                                            vertexCount: renderable.vertexCount,
                                            instanceCount: 1)
    }

    private func createUniforms(modelMatrix: GLKMatrix4) -> MTLBuffer {
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
}