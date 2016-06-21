//
//  MutableCharacteristic.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableCharacteristic: RxMutableCharacteristicType {
    let characteristic: RxMutableCharacteristicType
    
    public let service: MutableService
    
    /**
     The Bluetooth UUID of the `Characteristic` instance.
     */
    public var UUID: CBUUID {
        return characteristic.UUID
    }
    
    /**
     Current value of characteristic. If value is not present - it's `nil`.
     */
    public var value: NSData? {
        return characteristic.value
    }
    
    /**
     Flag which is set to true if characteristic is currently notifying
     */
    public var isNotifying: Bool {
        return characteristic.isNotifying
    }
    
    /**
     Properties of characteristic. For more info about this refer to ['CBCharacteristicProperties`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/#//apple_ref/c/tdef/CBCharacteristicProperties)
     */
    public var properties: CBCharacteristicProperties {
        return characteristic.properties
    }
    
    /**
     Value of this property is an array of `Descriptor` objects. They provide more detailed information
     about characteristics value.
     */
    public var descriptors: [MutableDescriptor]? {
        return characteristic.descriptors?.map {
            MutableDescriptor(descriptor: $0, characteristic: self)
        }
    }
    
    public var permissions: CBAttributePermissions {
        return characteristic.permissions
    }
    
    init(characteristic: RxMutableCharacteristicType, service: MutableService) {
        self.characteristic = characteristic
        self.service = service
    }
    
}