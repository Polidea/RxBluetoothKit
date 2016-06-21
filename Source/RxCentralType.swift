//
//  RxCentralType.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol RxCentralType {
    
    var central: CBCentral { get }
    
    var maximumUpdateValueLength: Int { get }
    
    var identifier: NSUUID { get }
    
}