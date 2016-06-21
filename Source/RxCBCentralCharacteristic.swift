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
    
    var uuid: CBUUID {
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
        guard let descriptors = characteristic.descriptors else {
            return nil
        }
        return descriptors.map {
            RxCBMutableDescriptor(descriptor: $0)
        }
    }
    var service: RxServiceType {
        return RxCBService(service: characteristic.service)
    }
    
}