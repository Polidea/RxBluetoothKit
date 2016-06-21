//
//  MutableDescriptor.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableDescriptor {
    
    let descriptor: RxMutableDescriptorType
    
    public let characteristic: MutableCharacteristic
    
    /**
     The Bluetooth UUID of the `Descriptor` instance.
     */
    public var UUID: CBUUID {
        return descriptor.UUID
    }
    
    /**
     The value of the descriptor. It can be written and read through functions on `Descriptor` instance.
     */
    public var value: AnyObject? {
        return descriptor.value
    }

    init(descriptor: RxMutableDescriptorType, characteristic: MutableCharacteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }
    
}

extension MutableDescriptor: Equatable { }

/**
 Compare two mutable descriptors. MutableDescriptors are the same when their UUIDs are the same.
 
 - parameter lhs: First mutable descriptor to compare
 - parameter rhs: Second mutable descriptor to compare
 - returns: True if both mutable descriptor are the same.
 */
public func == (lhs: MutableDescriptor, rhs: MutableDescriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}
