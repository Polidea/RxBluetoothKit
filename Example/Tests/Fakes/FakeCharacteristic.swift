//
//  FakeCharacteristic.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 25.02.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth

class FakeCharacteristic: RxCharacteristicType {

    var uuid: CBUUID = CBUUID()
    var value: NSData? = nil
    var isNotifying: Bool = false
    var properties: CBCharacteristicProperties = .Notify

    var descriptors: [RxDescriptorType]? = nil

    let service: RxServiceType

    init(service: RxServiceType) {
        self.service = service
    }

}