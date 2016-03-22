//
//  RxServiceType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth

/**
 Protocol which wraps bluetooth service.
 */
public protocol RxServiceType {

    /// Service's UUID
    var uuid: CBUUID { get }

    /// Service's characteristics
    var characteristics: [RxCharacteristicType]? { get }

    /// Service's included services
    var includedServices: [RxServiceType]? { get }

    /// True if service is a primary service
    var isPrimary: Bool { get }
}

func == (lhs: RxServiceType, rhs: RxServiceType) -> Bool {
    return lhs.uuid == rhs.uuid
}

func == (lhs: [RxServiceType], rhs: [RxServiceType]) -> Bool {
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
