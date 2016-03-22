//
//  RxCharacteristicType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth

/**
 Protocol which wraps characteristic for bluetooth devices.
 */
public protocol RxCharacteristicType {

    /// Characteristic UUID
    var uuid: CBUUID { get }

    /// Current characteristic value
    var value: NSData? { get }

    /// True if characteristic value changes are notified
    var isNotifying: Bool { get }

    /// Characteristic properties
    var properties: CBCharacteristicProperties { get }

    /// Characteristic descriptors
    var descriptors: [RxDescriptorType]? { get }

    /// Characteristic service
    var service: RxServiceType { get }
}

/**
 Characteristics are equal if their UUIDs are equal

 - parameter lhs: First characteristic to compare
 - parameter rhs: Second characteristic to compare
 - returns: True if characteristics are the same
 */
public func == (lhs: RxCharacteristicType, rhs: RxCharacteristicType) -> Bool {
    return lhs.uuid == rhs.uuid
}

/**
 Function compares if two characteristic arrays are the same, which is true if
 both of them in sequence are equal and their size is the same.

 - parameter lhs: First array of characteristics to compare
 - parameter rhs: Second array of characteristics to compare
 - returns: True if both arrays contain same characteristics
 */
func == (lhs: [RxCharacteristicType], rhs: [RxCharacteristicType]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    var i1 = lhs.generate()
    var i2 = rhs.generate()
    var isEqual = true
    while let e1 = i1.next(), e2 = i2.next() where isEqual {
        isEqual = e1 == e2
    }
    return isEqual
}
