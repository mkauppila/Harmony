//
//  ComponentStoreTest.swift
//  Harmony
//
//  Created by Markus Kauppila on 11/08/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Quick
import Nimble
@testable import Harmony

class TestComponent: Component {
    fileprivate (set) var objectId: GameObjectId

    let value: Int

    init(objectId: GameObjectId, value: Int) {
        self.objectId = objectId
        self.value = value
    }
}

class ComponentStoreSpec: QuickSpec {
    let store = ComponentStore()
    let objectId = 1

    override func spec() {
        it("should be able to register components") {
            self.store.registerComponent(TestComponent.self)
            expect(self.store.isComponentRegistered(TestComponent.self)).to(beTrue())
        }

        it("should be able to add components") {
            expect(self.store.isComponentRegistered(TestComponent.self)).to(beTrue())


            self.store.addComponent(TestComponent(objectId: self.objectId, value: 100),
                                               forObjectId: self.objectId)
            let c: TestComponent = self.store.findComponent(TestComponent.self,
                      forObjectId: self.objectId)!
            expect(c.value).to(equal(100))
        }

        // test fetching for component that is not registered

        // These test are depending on each other :/
        it("should be able to deregister components") {
            self.store.deregisterComponent(TestComponent.self)
            expect(self.store.isComponentRegistered(TestComponent.self)).to(beFalse())
        }
    }
}
