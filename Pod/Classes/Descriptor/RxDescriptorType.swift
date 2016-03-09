//
//  RxDescriptorType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import CoreBluetooth


public protocol RxDescriptorType {

    var UUID: CBUUID { get }
    var characteristic: RxCharacteristicType { get }
    var value: AnyObject? { get }

}