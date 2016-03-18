//
//  RxCBPeripheral.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth
import RxSwift

public class RxCBPeripheral: RxPeripheralType {

    let peripheral: CBPeripheral
    private let internalDelegate: InternalPeripheralDelegate

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.internalDelegate = RxCBPeripheral.getInternalPeripheralDelegateRef(peripheral)
    }

    deinit {
        RxCBPeripheral.putInternalPeripheralDelegateRef(peripheral)
    }
    
    public var identifier: NSUUID {
        return peripheral.identifier
    }

    public var name: String? {
        return peripheral.name
    }

    public var state: CBPeripheralState {
        return peripheral.state
    }
    public var services: [RxServiceType]? {
        guard let services = peripheral.services else {
            return nil
        }
        return services.map {
            RxCBService(service: $0)
        }
    }


    public var rx_didUpdateName: Observable<String?> {
        return internalDelegate.peripheralDidUpdateNameSubject
    }

    public var rx_didModifyServices: Observable<([RxServiceType])> {
        return internalDelegate.peripheralDidModifyServicesSubject
    }
    public var rx_didReadRSSI: Observable<(Int, NSError?)> {
        return internalDelegate.peripheralDidReadRSSISubject
    }

    public var rx_didDiscoverServices: Observable<([RxServiceType]?, NSError?)> {
        return internalDelegate.peripheralDidDiscoverServicesSubject
    }

    public var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverIncludedServicesForServiceSubject
    }

    public var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverCharacteristicsForServiceSubject
    }
    public var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidUpdateValueForCharacteristicSubject
    }

    public var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidWriteValueForCharacteristicSubject
    }
    public var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidUpdateNotificationStateForCharacteristicSubject
    }
    public var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverDescriptorsForCharacteristicSubject
    }
    public var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, NSError?)> {
        return internalDelegate.peripheralDidUpdateValueForDescriptorSubject
    }
    public var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, NSError?)> {
        return internalDelegate.peripheralDidWriteValueForDescriptorSubject
    }

    public func discoverServices(serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }

    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, forService service: RxServiceType) {
        peripheral.discoverCharacteristics(characteristicUUIDs, forService: (service as! RxCBService).service)
    }

    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, forService service: RxServiceType) {
        peripheral.discoverIncludedServices(includedServiceUUIDs, forService: (service as! RxCBService).service)
    }

    public func readValueForCharacteristic(characteristic: RxCharacteristicType) {
        peripheral.readValueForCharacteristic((characteristic as! RxCBCharacteristic).characteristic)
    }

    public func writeValue(data: NSData, forCharacteristic characteristic: RxCharacteristicType, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, forCharacteristic: (characteristic as! RxCBCharacteristic).characteristic, type: type)
    }

    public func setNotifyValue(enabled: Bool, forCharacteristic characteristic: RxCharacteristicType) {
        peripheral.setNotifyValue(enabled, forCharacteristic: (characteristic as! RxCBCharacteristic).characteristic)
    }

    public func discoverDescriptorsForCharacteristic(characteristic: RxCharacteristicType) {
        peripheral.discoverDescriptorsForCharacteristic((characteristic as! RxCBCharacteristic).characteristic)
    }

    public func readValueForDescriptor(descriptor: RxDescriptorType) {
        peripheral.readValueForDescriptor((descriptor as! RxCBDescriptor).descriptor)
    }

    public func writeValue(data: NSData, forDescriptor descriptor: RxDescriptorType) {
        peripheral.writeValue(data, forDescriptor: (descriptor as! RxCBDescriptor).descriptor)
    }

    public func readRSSI() {
        peripheral.readRSSI()
    }

    @objc private class InternalPeripheralDelegate: NSObject, CBPeripheralDelegate {
        let peripheralDidUpdateNameSubject = PublishSubject<String?>()
        let peripheralDidModifyServicesSubject = PublishSubject<([RxServiceType])>()
        let peripheralDidReadRSSISubject = PublishSubject<(Int, NSError?)>()
        let peripheralDidDiscoverServicesSubject = PublishSubject<([RxServiceType]?, NSError?)>()
        let peripheralDidDiscoverIncludedServicesForServiceSubject = PublishSubject<(RxServiceType, NSError?)>()
        let peripheralDidDiscoverCharacteristicsForServiceSubject = PublishSubject<(RxServiceType, NSError?)>()
        let peripheralDidUpdateValueForCharacteristicSubject = PublishSubject<(RxCharacteristicType, NSError?)>()
        let peripheralDidWriteValueForCharacteristicSubject = PublishSubject<(RxCharacteristicType, NSError?)>()
        let peripheralDidUpdateNotificationStateForCharacteristicSubject = PublishSubject<(RxCharacteristicType, NSError?)>()
        let peripheralDidDiscoverDescriptorsForCharacteristicSubject = PublishSubject<(RxCharacteristicType, NSError?)>()
        let peripheralDidUpdateValueForDescriptorSubject = PublishSubject<(RxDescriptorType, NSError?)>()
        let peripheralDidWriteValueForDescriptorSubject = PublishSubject<(RxDescriptorType, NSError?)>()


        @objc func peripheralDidUpdateName(peripheral: CBPeripheral) {
            peripheralDidUpdateNameSubject.onNext(peripheral.name)
        }

        @objc func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
            peripheralDidModifyServicesSubject.onNext(invalidatedServices.map {
                RxCBService(service: $0)
            })
        }


        @objc func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
            peripheralDidReadRSSISubject.onNext((RSSI.integerValue, error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
            peripheralDidDiscoverServicesSubject.onNext((peripheral.services?.map {
                RxCBService(service: $0)
            }, error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
            peripheralDidDiscoverIncludedServicesForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
            peripheralDidDiscoverCharacteristicsForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            peripheralDidUpdateValueForCharacteristicSubject.onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            peripheralDidWriteValueForCharacteristicSubject.onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            peripheralDidUpdateNotificationStateForCharacteristicSubject.onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            peripheralDidDiscoverDescriptorsForCharacteristicSubject.onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
            peripheralDidUpdateValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }

        @objc func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
            peripheralDidWriteValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }
    }

    private class InternalPeripheralDelegateWrapper {
        private let delegate: InternalPeripheralDelegate
        private var refCount: Int

        private init(delegate: InternalPeripheralDelegate) {
            self.delegate = delegate
            self.refCount = 1
        }
    }

    private static let internalPeripheralDelegateWrappersLock = NSLock()
    private static var internalPeripheralDelegateWrappers = [CBPeripheral:InternalPeripheralDelegateWrapper]()

    private static func getInternalPeripheralDelegateRef(cbPeripheral: CBPeripheral) -> InternalPeripheralDelegate {
        internalPeripheralDelegateWrappersLock.lock(); defer { internalPeripheralDelegateWrappersLock.unlock() }

        if let wrapper = internalPeripheralDelegateWrappers[cbPeripheral] {
            wrapper.refCount += 1
            return wrapper.delegate
        } else {
            let delegate = InternalPeripheralDelegate()
            cbPeripheral.delegate = delegate
            internalPeripheralDelegateWrappers[cbPeripheral] = InternalPeripheralDelegateWrapper(delegate: delegate)
            return delegate
        }
    }

    private static func putInternalPeripheralDelegateRef(cbPeripheral: CBPeripheral) {
        internalPeripheralDelegateWrappersLock.lock(); defer { internalPeripheralDelegateWrappersLock.unlock() }

        if let wrapper = internalPeripheralDelegateWrappers[cbPeripheral] {
            wrapper.refCount -= 1
            if wrapper.refCount == 0 {
                cbPeripheral.delegate = nil
                internalPeripheralDelegateWrappers[cbPeripheral] = nil
            }
        } else {
            fatalError("Implementation error: internal delegate for CBPeripheral is cached in memory")
        }
    }
}
