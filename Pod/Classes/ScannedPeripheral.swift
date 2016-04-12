//
//  ScannedPeripheral.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth

/// Represents instance of scanned peripheral - containing it's advertisment data, rssi and peripheral itself
public class ScannedPeripheral {

    /// Scanned peripheral
    public let peripheral: Peripheral

    /// Advertisement data of scanned peripheral
    public let advertisementData: AdvertisementData

    /// Scanned peripheral's RSSI
    public let RSSI: NSNumber

    /**
     Create new scanned peripheral.
     - parameter peripheral: Scanned peripheral
     - parameter advertisementData: Advertisement data of scanned peripheral
     - parameter RSSI: RSSI of scanned peripheral
     */
    public init(peripheral: Peripheral, advertisementData: AdvertisementData, RSSI: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
    }
}
