//
//  RxCBDescriptor.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth

class RxCBDescriptor: RxDescriptorType {

    let descriptor: CBDescriptor

    init(descriptor: CBDescriptor) {
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
