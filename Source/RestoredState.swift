//
//  RestoredState.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 21.05.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Convenience class which helps reading state of restored BluetoothManager
 */
public struct RestoredState {

    public let restoredStateData: [String:AnyObject]

    let bluetoothManager: BluetoothManager
    /**
     Creates restored state information based on CoreBluetooth's dictionary

     - parameter restoredState: Core Bluetooth's restored state data
     */
    init(restoredStateDictionary: [String:AnyObject], bluetoothManager: BluetoothManager) {
        self.restoredStateData = restoredStateDictionary
        self.bluetoothManager = bluetoothManager
    }

    /**
     Creates restored state information based on CoreBluetooth's dictionary

     - parameter restoredState: Core Bluetooth's restored state data
     */
    var peripherals: [Peripheral] {
        let objects = restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }
        return arrayOfAnyObjects.flatMap { $0 as? CBPeripheral }
            .map { RxCBPeripheral(peripheral: $0) }
            .map { Peripheral(manager: bluetoothManager, peripheral: $0) }
    }

    var scanOptions: [String : AnyObject]? {
        return restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [String : AnyObject]
    }

    var services: [Service] {
        let objects = restoredStateData[CBCentralManagerRestoredStateScanServicesKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }
        return arrayOfAnyObjects.flatMap { $0 as? CBService }
            .map { RxCBService(service: $0) }
            .map { Service(peripheral: Peripheral(manager: bluetoothManager,
                peripheral: RxCBPeripheral(peripheral: $0.service.peripheral)), service: $0) }
    }
}