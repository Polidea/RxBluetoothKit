//
//  Boxes.swift
//  Pods
//
//  Created by Przemysław Lenart on 26/02/16.
//
//

import Foundation


class MutableBox<T> : CustomDebugStringConvertible {
    var value : T?
    
    init() {}
    init(value: T) {
        self.value = value
    }
}

extension MutableBox {
    var debugDescription: String {
        get {
            return "MutatingBox(\(self.value))"
        }
    }
}