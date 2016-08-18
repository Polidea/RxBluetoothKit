//
//  RxCBCentral.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

class RxCBCentral: RxCentralType {
    
    let central: CBCentral
    
    init(central: CBCentral) {
        self.central = central
    }
    
    var identifier: NSUUID {
        return central.identifier
    }
    
    var maximumUpdateValueLength: Int {
        return central.maximumUpdateValueLength
    }
}