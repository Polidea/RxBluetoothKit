//
//  RxMutableDescriptorType.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol RxMutableDescriptorType {
    
    /// Descriptor UUID
    var UUID: CBUUID { get }
    
    /// Descriptor's characteristic
    var characteristic: RxMutableCharacteristicType { get }
    
    /// Descriptor's value
    var value: AnyObject? { get }
}

func == (lhs: RxMutableDescriptorType, rhs: RxMutableDescriptorType) -> Bool {
    return lhs.UUID == rhs.UUID
}
