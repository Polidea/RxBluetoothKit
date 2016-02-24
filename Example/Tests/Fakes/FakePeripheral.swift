//
//  FakePeripheral.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 24.02.2016.
//



import Foundation
import RxSwift
import CoreBluetooth
import RxTests
import RxBluetoothKit
class FakePeripheral: RxPeripheralType {
    
    
    var name: String? = nil
    var state: CBPeripheralState = CBPeripheralState.Connected
    var services: [RxServiceType]? = nil
    var identifier: NSUUID = NSUUID()
    
    var RSSI: NSNumber? = nil

    
    var rx_didUpdateName: Observable<String?> = .never()
    var rx_didModifyServices: Observable<[RxServiceType]> = .never()
    var rx_didReadRSSI: Observable<(NSNumber, NSError?)> = .never()
    var rx_didDiscoverServices: Observable<([RxServiceType]?, NSError?)> = .never()
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, NSError?)> = .never()
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, NSError?)> = .never()
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> = .never()
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> = .never()
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, NSError?)> = .never()
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, NSError?)> = .never()
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, NSError?)> = .never()
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, NSError?)> = .never()
    
    
    
    var discoverServicesTO: TestableObserver<[CBUUID]?>?
    func discoverServices(serviceUUIDs: [CBUUID]?) {
        discoverServicesTO?.onNext(serviceUUIDs)
    }
    
    var discoverCharacteristicsTO: TestableObserver<([CBUUID]?, RxServiceType)>?
    func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, forService: RxServiceType) {
        discoverCharacteristicsTO?.onNext((characteristicUUIDs, forService))
    }
    
    var discoverIncludedServicesTO: TestableObserver<([CBUUID]?, RxServiceType)>?
    func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, forService service: RxServiceType) {
        discoverIncludedServicesTO?.onNext((includedServiceUUIDs, service))
    }
    
    var readValueForCharacteristicTO: TestableObserver<RxCharacteristicType>?
    func readValueForCharacteristic(characteristic: RxCharacteristicType) {
        readValueForCharacteristicTO?.onNext(characteristic)
    }
    
    var writeValueForCharacteristicTypeTO: TestableObserver<(NSData, RxCharacteristicType, CBCharacteristicWriteType)>?
    func writeValue(data: NSData, forCharacteristic characteristic: RxCharacteristicType, type: CBCharacteristicWriteType) {
        writeValueForCharacteristicTypeTO?.onNext((data, characteristic, type))
    }
    
    var setNotifyValueForCharacteristicTO: TestableObserver<(Bool, RxCharacteristicType)>?
    func setNotifyValue(enabled: Bool, forCharacteristic characteristic: RxCharacteristicType) {
        setNotifyValueForCharacteristicTO?.onNext((enabled, characteristic))
    }
    
    var discoverDescriptorsForCharacteristicTO: TestableObserver<RxCharacteristicType>?
    func discoverDescriptorsForCharacteristic(characteristic: RxCharacteristicType) {
        discoverDescriptorsForCharacteristicTO?.onNext(characteristic)
    }
    
    var readValueForDescriptorTO: TestableObserver<RxDescriptorType>?
    func readValueForDescriptor(descriptor: RxDescriptorType) {
        readValueForDescriptorTO?.onNext(descriptor)
    }
    
    var writeValueForDescriptorTO: TestableObserver<(NSData, RxDescriptorType)>?
    func writeValue(data: NSData, forDescriptor descriptor: RxDescriptorType) {
        writeValueForDescriptorTO?.onNext((data, descriptor))
    }
    var readRSSITO: TestableObserver<Void>?
    func readRSSI() {
        readRSSITO?.onNext()
    }
    
    
    
}
