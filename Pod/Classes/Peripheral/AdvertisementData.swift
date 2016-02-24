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
    private let advertisementData : [String : AnyObject]
    
    public init(advertisementData: [String : AnyObject]) {
        self.advertisementData = advertisementData
    }
    public var localName : String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }
    public var manufacturerData : NSData? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
    }
    public var serviceData : [CBUUID: NSData]? {
        return advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData]
    }
    public var serviceUUIDs : [CBUUID]? {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    public var overflowServiceUUIDs : [CBUUID]? {
        return advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    public var txPowerLevel : NSNumber? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }
    public var isConnectable : Bool? {
        return advertisementData[CBAdvertisementDataIsConnectable] as? Bool
    }
    public var solicitedServiceUUIDs : [CBUUID]? {
        return advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}