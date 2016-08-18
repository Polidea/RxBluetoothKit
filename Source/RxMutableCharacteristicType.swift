//
//  RxMutableCharacteristicType.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol RxMutableCharacteristicType {
    
    /// Characteristic service
    var service: RxMutableServiceType { get }
    
    /// Characteristic UUID
    var UUID: CBUUID { get }
    
    /// Current characteristic value
    var value: NSData? { get }
    
    /// True if characteristic value changes are notified
    var isNotifying: Bool { get }
    
    /// Characteristic properties
    var properties: CBCharacteristicProperties { get }
    
    /// Characteristic descriptors
    var descriptors: [RxMutableDescriptorType]? { get }
    
    var permissions: CBAttributePermissions { get }
    
}

/**
 Characteristics are equal if their UUIDs are equal
 
 - parameter lhs: First characteristic to compare
 - parameter rhs: Second characteristic to compare
 - returns: True if characteristics are the same
 */
func == (lhs: RxMutableCharacteristicType, rhs: RxMutableCharacteristicType) -> Bool {
    return lhs.UUID == rhs.UUID
}

/**
 Function compares if two characteristic arrays are the same, which is true if
 both of them in sequence are equal and their size is the same.
 
 - parameter lhs: First array of characteristics to compare
 - parameter rhs: Second array of characteristics to compare
 - returns: True if both arrays contain same characteristics
 */
func == (lhs: [RxMutableCharacteristicType], rhs: [RxMutableCharacteristicType]) -> Bool {
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
