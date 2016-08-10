//
//  EntityComponentStore.swift
//  Harmony
//
//  Created by Markus Kauppila on 29/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation

// TODO This is very nicely unit testable
// TODO try to use `map` instead of the endless switch-case swamp
class ComponentStore {
    private var renderables: [GameObjectId: Renderable]
    private var transforms: [GameObjectId: Transform]
    private var lanePositions: [GameObjectId: LanePosition]

    init() {
        renderables = [GameObjectId: Renderable]()
        transforms = [GameObjectId: Transform]()
        lanePositions = [GameObjectId: LanePosition]()
    }

    func addComponentForObjectId<T: Component>(component: T, objectId: GameObjectId) {
        switch T.self {
        case is Renderable.Type:
            renderables[objectId] = component as? Renderable
        case is Transform.Type:
            transforms[objectId] = component as? Transform
        case is LanePosition.Type:
            lanePositions[objectId] = component as? LanePosition
        default:
            break
        }
    }

    func removeComponentForObjectId<T: Component>(component: T, objectId: GameObjectId) {
        switch T.self {
        case is Renderable.Type:
            renderables.removeValueForKey(objectId)
        case is Transform.Type:
            transforms.removeValueForKey(objectId)
        case is LanePosition.Type:
            lanePositions.removeValueForKey(objectId)
        default:
            break
        }
    }

    func findComponentForObjectId<T: Component>(objectId: GameObjectId) -> T? {
        switch T.self {
        case is Renderable.Type:
            return renderables[objectId] as? T
        case is Transform.Type:
            return transforms[objectId] as? T
        case is LanePosition.Type:
            return lanePositions[objectId] as? T
        default:
            return nil
        }
    }

    func allComponentsOfType<T: Component>() -> [T] {
        switch T.self {
        case is Renderable.Type:
            return renderables.map({ (_, renderable) -> T in
                return renderable as! T
            })
        case is Transform.Type:
            return transforms.map({ (_, transform) -> T in
                return transform as! T
            })
        case is LanePosition.Type:
            return lanePositions.map({ (_, lanePosition) -> T in
                return lanePosition as! T
            })
        default:
            return []
        }
    }
}
