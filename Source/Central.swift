//
//  Central.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

public class Central {
    
    // implementaion of CBCentral
    let central: RxCentralType
    
    init(central: RxCentralType) {
        self.central = central
    }
        
}