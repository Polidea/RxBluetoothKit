//
//  FakeDescriptor.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 25.02.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
@testable
import RxBluetoothKit
import CoreBluetooth

class FakeDescriptor: RxDescriptorType {

    var UUID = CBUUID()
    var characteristic: RxCharacteristicType
    var value: AnyObject? = nil
    init(characteristic: RxCharacteristicType) {
        self.characteristic = characteristic
    }
}