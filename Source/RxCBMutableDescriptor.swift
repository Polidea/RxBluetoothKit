//
//  RxCBMutableDescriptor.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

class RxCBMutableDescriptor: RxMutableDescriptorType {
    
    let descriptor: CBMutableDescriptor
    
    init(descriptor: CBMutableDescriptor) {
        self.descriptor = descriptor
    }
    
    var UUID: CBUUID {
        return descriptor.UUID
    }
    var characteristic: RxCharacteristicType {
        return RxCBCharacteristic(characteristic: descriptor.characteristic)
    }
    var value: AnyObject? {
        return descriptor.value
    }
    
}