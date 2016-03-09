//
//  RxPeripheralType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import RxSwift
import CoreBluetooth

public protocol RxPeripheralType {

    var name: String? { get }
    var identifier: NSUUID { get }
    var state: CBPeripheralState { get }
    var services: [RxServiceType]? { get }

    var rx_didUpdateName: Observable<String?> { get }
    var rx_didModifyServices: Observable<([RxServiceType])> { get }
    var rx_didReadRSSI: Observable<(Int, NSError?)> { get }
    var rx_didDiscoverServices: Observable<([RxServiceType]?, NSError?)> { get }
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, NSError?)> { get }
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, NSError?)> { get }
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> { get }
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> { get }
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, NSError?)> { get }
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, NSError?)> { get }
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, NSError?)> { get }
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, NSError?)> { get }


    func discoverServices(serviceUUIDs: [CBUUID]?)

    func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, forService: RxServiceType)

    func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, forService service: RxServiceType)

    func readValueForCharacteristic(characteristic: RxCharacteristicType)

    func writeValue(data: NSData, forCharacteristic characteristic: RxCharacteristicType, type: CBCharacteristicWriteType)

    func setNotifyValue(enabled: Bool, forCharacteristic characteristic: RxCharacteristicType)

    func discoverDescriptorsForCharacteristic(characteristic: RxCharacteristicType)

    func readValueForDescriptor(descriptor: RxDescriptorType)

    func writeValue(data: NSData, forDescriptor descriptor: RxDescriptorType)

    func readRSSI()

}


public func ==(lhs: RxPeripheralType, rhs: RxPeripheralType) -> Bool {
    return lhs.identifier == rhs.identifier
}
