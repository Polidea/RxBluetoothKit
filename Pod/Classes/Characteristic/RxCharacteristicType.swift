//
//  RxCharacteristicType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth

public protocol RxCharacteristicType {

    var uuid: CBUUID { get }
    var value: NSData? { get }
    var isNotifying: Bool { get }
    var properties: CBCharacteristicProperties { get }
    var descriptors: [RxDescriptorType]? { get }
    var service: RxServiceType { get }

}

public func ==(lhs: RxCharacteristicType, rhs: RxCharacteristicType) -> Bool {
    return lhs.uuid == rhs.uuid
}

func ==(lhs: [RxCharacteristicType], rhs: [RxCharacteristicType]) -> Bool {
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