//
//  RestoredState.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 21.05.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation

/**
 Convenience class which helps reading state of restored BluetoothManager
 */
public struct RestoredState {

    public let restoredStateData: [String:AnyObject]
    /**
     Creates restored state information based on CoreBluetooth's dictionary

     - parameter restoredState: Core Bluetooth's restored state data
     */
    init(restoredStateDictionary: [String:AnyObject]) {
        self.restoredStateData = restoredStateDictionary
    }
}