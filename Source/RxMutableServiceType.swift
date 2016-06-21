//
//  RxMutableServiceType.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol RxMutableServiceType {
    
    /// Service's UUID
    var uuid: CBUUID { get }
    
    /// Service's characteristics
    var characteristics: [RxMutableCharacteristicType]? { get }
    
    /// Service's included services
    // this is the only thing MutableService needs to override from Service
    var includedServices: [RxMutableServiceType]? { get }
    
    /// True if service is a primary service
    var isPrimary: Bool { get }

}