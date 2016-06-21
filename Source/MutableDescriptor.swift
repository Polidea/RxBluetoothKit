//
//  MutableDescriptor.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableDescriptor: RxMutableDescriptorType {
    
    let descriptor: RxMutableDescriptorType
    
    /**
     The Bluetooth UUID of the `Descriptor` instance.
     */
    public var UUID: CBUUID {
        return descriptor.UUID
    }
    
    public let characteristic: MutableCharacteristic
    
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