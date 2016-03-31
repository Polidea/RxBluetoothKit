//
//  Descriptor.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth

/**
 Class which describes characteristic's descriptor
 */
public class Descriptor {

    let descriptor: RxDescriptorType

    /// Characteristic to which this descriptor belongs
    public let characteristic: Characteristic

    /// Descriptor UUID
    public var UUID: CBUUID {
        return descriptor.UUID
    }

    /// Descriptor value
    public var value: AnyObject? {
        return descriptor.value
    }

    init(descriptor: RxDescriptorType, characteristic: Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }
}
extension Descriptor: Equatable { }

public func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}