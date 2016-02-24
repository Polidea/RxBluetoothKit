//
//  RxCBCharacteristic.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth
import RxSwift

class RxCBCharacteristic: RxCharacteristicType {
    
    let characteristic: CBCharacteristic
    
    init(characteristic: CBCharacteristic) {
        self.characteristic = characteristic
    }
    
    var uuid: CBUUID { return characteristic.UUID }
    var value: NSData? { return characteristic.value }
    var isNotifying: Bool { return characteristic.isNotifying }
    var properties: CBCharacteristicProperties { return characteristic.properties }
    var descriptors: [RxDescriptorType]? {
        guard let descriptors = characteristic.descriptors else { return nil }
        return descriptors.map { RxCBDescriptor(descriptor: $0) }
    }
    var service: RxServiceType { return RxCBService(service: characteristic.service) }
    
}