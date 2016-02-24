//
//  FakeService.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 25.02.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth

class FakeService: RxServiceType {
    
    var uuid: CBUUID  = CBUUID()
    
    var characteristics: [RxCharacteristicType]?  = nil
    var includedServices: [RxServiceType]?  = nil
    var isPrimary: Bool = false
}