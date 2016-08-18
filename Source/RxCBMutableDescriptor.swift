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
    var characteristic: RxMutableCharacteristicType {
        guard let mutableCharacteristic = descriptor.characteristic as? CBMutableCharacteristic else {
            assertionFailure()
            return RxCBMutableCharacteristic(characteristic: descriptor.characteristic as! CBMutableCharacteristic)
        }
        
        return RxCBMutableCharacteristic(characteristic: mutableCharacteristic)
    }
    var value: AnyObject? {
        return descriptor.value
    }
    
}