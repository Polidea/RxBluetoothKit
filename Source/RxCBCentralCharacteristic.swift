//
//  RxCBCentralCharacteristic.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

class RxCBMutableCharacteristic: RxMutableCharacteristicType {
    
    let characteristic: CBMutableCharacteristic
    
    init(characteristic: CBMutableCharacteristic) {
        self.characteristic = characteristic
    }
    
    var UUID: CBUUID {
        return characteristic.UUID
    }
    var value: NSData? {
        return characteristic.value
    }
    var isNotifying: Bool {
        return characteristic.isNotifying
    }
    var properties: CBCharacteristicProperties {
        return characteristic.properties
    }
    var descriptors: [RxMutableDescriptorType]? {
        guard
            let descriptors = characteristic.descriptors,
            let mutableDescriptors = descriptors as? [CBMutableDescriptor] else {
            return nil
        }
        return mutableDescriptors.map {
            RxCBMutableDescriptor(descriptor: $0)
        }
    }
    var permissions: CBAttributePermissions {
        return characteristic.permissions
    }
    var service: RxMutableServiceType {
        guard let mutableService = characteristic.service as? CBMutableService else {
            assertionFailure()
            return RxCBMutableService(service: CBMutableService(type: characteristic.service.UUID, primary: characteristic.service.isPrimary)) // maybe this should be the default
        }
        
        return RxCBMutableService(service: mutableService)
    }
    
    
}