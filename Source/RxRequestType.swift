//
//  RxRequestType.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation

protocol RxRequestType {

    var central: Central { get }
    
    var characteristic: Characteristic { get }
    
    var offset: Int { get }
    
    var value: NSData? { get }

}