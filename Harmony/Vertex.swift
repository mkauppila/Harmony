//
//  Vertex.swift
//  Harmony
//
//  Created by Markus Kauppila on 19/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation
import Metal
import GLKit

struct Vertex {
    let position: GLKVector3
    let color: GLKVector4
    
    func floatBuffer() -> [Float] {
        return [position.x, position.y, position.z, color.r, color.g, color.b, color.a]
    }
}
