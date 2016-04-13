//
//  RxDescriptorType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth

/**
 Protocol which wraps characteristic's descriptor for bluetooth devices.
 */
public protocol RxDescriptorType {

    /// Descriptor UUID
    var UUID: CBUUID { get }

    /// Descriptor's characteristic
    var characteristic: RxCharacteristicType { get }

    /// Descriptor's value
    var value: AnyObject? { get }
}

public func == (lhs: RxDescriptorType, rhs: RxDescriptorType) -> Bool {
    return lhs.UUID == rhs.UUID
}
