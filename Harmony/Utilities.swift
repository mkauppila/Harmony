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
    return GLKMatrix4Identity
}

func GLKMatrix4ToUnsafePointer(_ matrix: GLKMatrix4) -> UnsafeRawPointer { ///UnsafePointer<Float> {
    // return UnsafePointer<Float>(Array(arrayLiteral: matrix.m))

    return nil // UnsafeRawPointer()

    // withMemoryRebound(to: )
    // UnsafePointer<Float>.withMemoryRebound(to:)
}

