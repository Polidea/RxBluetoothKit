//
//  Descriptor.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth

public class Descriptor {
    
    let descriptor: RxDescriptorType
    
    public let characteristic: Characteristic
    
    public var UUID: CBUUID { return descriptor.UUID }
    public var value: AnyObject? { return descriptor.value }
    
    init(descriptor: RxDescriptorType, characteristic: Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }

}