//
//  AdvertisementData.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth


public struct AdvertisementData {
    private let advertisementData: [String:AnyObject]

    public init(advertisementData: [String:AnyObject]) {
        self.advertisementData = advertisementData
    }
    ///A string containing the local name of a peripheral.
    public var localName: String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }
    ///A NSData object containing the manufacturer data of a peripheral.
    public var manufacturerData: NSData? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
    }
    /**
    A dictionary containing service-specific advertisement data.
    The keys are CBUUID objects, representing CBService UUIDs. The values are NSData objects,
    representing service-specific data.
    */
    public var serviceData: [CBUUID:NSData]? {
        return advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID:NSData]
    }
    ///An array of service UUIDs.
    public var serviceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    ///An array of one or more CBUUID objects, representing CBService UUIDs that were found in the “overflow”
    ///area of the advertisement data.
    public var overflowServiceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    /**
    A number (an instance of NSNumber) containing the transmit power of a peripheral.
    This key and value are available if the broadcaster (peripheral)
    provides its Tx power level in its advertising packet.
    Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    */
    public var txPowerLevel: NSNumber? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }
    /**
     A Boolean value that indicates whether the advertising event type is connectable.
     The value for this key is an NSNumber object. You can use this value to determine whether
     a peripheral is connectable at a particular moment.
    */
    public var isConnectable: Bool? {
        return advertisementData[CBAdvertisementDataIsConnectable] as? Bool
    }
    ///An array of one or more CBUUID objects, representing CBService UUIDs.
    public var solicitedServiceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}