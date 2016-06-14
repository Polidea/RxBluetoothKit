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
    
    var identifier: NSUUID {
        return central.identifier
    }
    
    init(central: CBCentral) {
        self.central = central
    }
}