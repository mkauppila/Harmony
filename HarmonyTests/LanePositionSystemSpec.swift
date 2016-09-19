//
// Created by Markus Kauppila on 12/09/16.
// Copyright (c) 2016 Markus Kauppila. All rights reserved.
//

import Quick
import Nimble
import GLKit

@testable import Harmony

class LanePositionSystemSpec: QuickSpec {
    let system = LanePositionSystem(store: ComponentStore())

    override func spec() {
        it("should be able to register components") {
//            self.system.calculatePlayerPositionBetweenVertices(GLKVector3Make(0.0, 0.0, 0.0),
//                    secondVertex: GLKVector3Make(1, 1, 1))
        }
    }
}
