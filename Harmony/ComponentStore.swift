//
//  EntityComponentStore.swift
//  Harmony
//
//  Created by Markus Kauppila on 29/06/16.
//  Copyright © 2016 Markus Kauppila. All rights reserved.
//

import Foundation

class ComponentStore {
    private var allComponents: [String: [GameObjectId: Component]]

    init() {
        allComponents = [String: [GameObjectId: Component]]()
    }

    func registerComponent(componentClass: AnyClass) {
        allComponents[NSStringFromClass(componentClass)] = [GameObjectId: Component]()
    }

    func deregisterComponent(componentClass: AnyClass) {
        allComponents.removeValueForKey(NSStringFromClass(componentClass))
    }

    func isComponentRegistered(componentClass: AnyClass) -> Bool {
        return allComponents[NSStringFromClass(componentClass)] != nil
    }



    func addComponent<T: Component>(component: T, forObjectId objectId: GameObjectId) {
        if let componentName = typeNameOfComponent(component),
           var comps = allComponents[componentName] {
            comps[objectId] = component
            allComponents[componentName] = comps
        }
    }

    func findComponent<T>(componentClass: AnyClass, forObjectId objectId: GameObjectId) -> T? {
        if let comps = allComponents[NSStringFromClass(componentClass)] {
            return comps[objectId] as? T
        } else {
            return nil
        }
    }

    func removeComponent<T: Component>(component: T, forObjectId objectId: GameObjectId) {
        if let componentName = typeNameOfComponent(component),
           var comps = allComponents[componentName] {
            comps.removeValueForKey(objectId)
        }
    }

    func allComponentsOfType<T: Component>(componentClass: AnyClass) -> [T] {
        if let comps = allComponents[NSStringFromClass(componentClass)] {
            return comps.map({ (_, c) -> T in
                return c as! T
            })
        } else {
            return []
        }
    }

    private func typeNameOfComponent<T: Component>(component: T) -> String? {
        if let classType = T.self as? AnyClass {
            return NSStringFromClass(classType)
        } else {
            print("ERROR: failed to get class type for component")
            print("       component: \(component)")
            return nil
        }
    }
}
