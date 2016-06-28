//
//  Utilities.swift
//  Harmony
//
//  Created by Markus Kauppila on 28/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation
import GLKit

func GLKMatrix4New() -> GLKMatrix4 {
    var matrix = GLKMatrix4()
    matrix = GLKMatrix4Identity
    return matrix
}

func GLKMatrix4ToUnsafePointer(matrix: GLKMatrix4) -> UnsafePointer<Float> {
    let a = Array(arrayLiteral: matrix.m)
    return UnsafePointer<Float>(a)
}

