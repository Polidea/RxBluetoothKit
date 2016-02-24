//
//  RxServiceType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth

public protocol RxServiceType {
    
    var uuid: CBUUID { get }
    var characteristics: [RxCharacteristicType]? { get }
    var includedServices: [RxServiceType]? { get }
    var isPrimary: Bool { get }
}

public func ==(lhs: RxServiceType, rhs: RxServiceType) -> Bool {
    return lhs.uuid == rhs.uuid
}

func ==(lhs: [RxServiceType], rhs: [RxServiceType]) -> Bool
{
    guard lhs.count == rhs.count else { return false }
    var i1 = lhs.generate()
    var i2 = rhs.generate()
    var isEqual = true
    while let e1 = i1.next(), e2 = i2.next() where isEqual
    {
        isEqual = e1 == e2
    }
    return isEqual
}