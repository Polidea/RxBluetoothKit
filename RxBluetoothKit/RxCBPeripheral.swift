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

/**
 Core Bluetooth implementation of RxPeripheralType. This is a lightweight wrapper which allows
 to hide all implementation details.
 */
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

    /// Peripheral's identifier
    public var identifier: NSUUID {
        return peripheral.identifier
    }

    /// Peripheral's name
    public var name: String? {
        return peripheral.name
    }

    /// Peripheral's state
    public var state: CBPeripheralState {
        return peripheral.state
    }

    /// Peripheral's services
    public var services: [RxServiceType]? {
        guard let services = peripheral.services else {
            return nil
        }
        return services.map {
            RxCBService(service: $0)
        }
    }

    /// Observable which emits peripheral's name changes
    public var rx_didUpdateName: Observable<String?> {
        return internalDelegate.peripheralDidUpdateNameSubject
    }

    /// Observable which emits when service's are modified
    public var rx_didModifyServices: Observable<([RxServiceType])> {
        return internalDelegate.peripheralDidModifyServicesSubject
    }

    /// Observable which emits when RSSI was read
    public var rx_didReadRSSI: Observable<(Int, NSError?)> {
        return internalDelegate.peripheralDidReadRSSISubject
    }

    /// Observable which emits discovered serivices during discovery
    public var rx_didDiscoverServices: Observable<([RxServiceType]?, NSError?)> {
        return internalDelegate.peripheralDidDiscoverServicesSubject
    }

    /// Observable which emits service for which included services were discovered
    public var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverIncludedServicesForServiceSubject
    }

    /// Observable which emits service for which characteristics were discovered
    public var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverCharacteristicsForServiceSubject
    }

    /// Observable which emits characteristic which value has been updated
    public var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidUpdateValueForCharacteristicSubject
    }

    /// Observable which emits characteristic for which value was written successfully
    public var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidWriteValueForCharacteristicSubject
    }

    /// Observable which emits characteristic which notification value was successfully modified
    public var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidUpdateNotificationStateForCharacteristicSubject
    }

    /// Observable which emits characteristic for which descriptors were discovered
    public var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, NSError?)> {
        return internalDelegate.peripheralDidDiscoverDescriptorsForCharacteristicSubject
    }

    /// Observable which emits descriptor which value was updated
    public var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, NSError?)> {
        return internalDelegate.peripheralDidUpdateValueForDescriptorSubject
    }

    /// Observable which emits descriptor which completed sucessfully its write operation
    public var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, NSError?)> {
        return internalDelegate.peripheralDidWriteValueForDescriptorSubject
    }

    /**
     Discover services with specified optional list of UUIDs. Passing `nil` will show all available services for
     peripheral. Results are returned by `rx_didDiscoverServices` observable after subscription.

     - parameter serviceUUIDs: List of UUIDS which must be implemented by a peripheral
     */
    public func discoverServices(serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }

    /**
     Discover characteristics for peripheral's service. If list is passed only characteristics with certain UUID are
     returned during discovery, otherwise all characteristics will be discovered for certain service. Results are
     returned by `rx_didDiscoverCharacteristicsForService` observable after subscription.

     - parameter characteristicUUIDs: List of UUIDs of characteristics which should be returned.
     - parameter forService: Serivce which includes characteristics
     */
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, forService service: RxServiceType) {
        peripheral.discoverCharacteristics(characteristicUUIDs, forService: (service as! RxCBService).service)
    }

    /**
     Discover included services inside of another service. Values are returned
     by `rx_didDiscoverIncludedServicesForService` observable which emits retults of this call after subscription.

     - parameter includedServiceUUIDs: List of included serive's UUID for which we are looking for. If `nil` is passed
                                       all included services will be discovered
     - parameter forService: Service which contains included services.
     */
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, forService service: RxServiceType) {
        peripheral.discoverIncludedServices(includedServiceUUIDs, forService: (service as! RxCBService).service)
    }

    /**
     Read value for characteristic. Result will be available in `rx_didUpdateValueForCharacteristic` observable after
     subscibe.
     - parameter characteristic: Characteristic from which we are reading
     */
    public func readValueForCharacteristic(characteristic: RxCharacteristicType) {
        peripheral.readValueForCharacteristic((characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Write value to characteristic. Confirmation that characteristic was read will be available in
     `rx_didWriteValueForCharacteristic` observable after subscribe.
     - parameter data: Data which will be written in characteristic
     - parameter forCharacteristic: Characteristic to which new value will be written.
     - parameter type: Type of write operation
     */
    public func writeValue(data: NSData,
                           forCharacteristic characteristic: RxCharacteristicType,
                           type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, forCharacteristic: (characteristic as! RxCBCharacteristic).characteristic,
                              type: type)
    }

    /**
     Set if notifications for characteristic value changes should be monitored on `rx_didUpdateValueForCharacteristic`
     - parameter enabled: True if notifications for value changes should be enabled
     - parameter forCharacteristic: Characteristic for which notifications will be enabled or disabled
     */
    public func setNotifyValue(enabled: Bool, forCharacteristic characteristic: RxCharacteristicType) {
        peripheral.setNotifyValue(enabled, forCharacteristic: (characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Discover descriptors for specific characteristic. Successful operation will be indicated in
     `rx_didDiscoverDescriptorsForCharacteristic` observable in subscription.

     - parameter characteristic: Characteristic for which descriptors will be discovered
     */
    public func discoverDescriptorsForCharacteristic(characteristic: RxCharacteristicType) {
        peripheral.discoverDescriptorsForCharacteristic((characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Read value for descriptor. Results will be available in `rx_didUpdateValueForDescriptor` observable after
     subscription.

     - parameter descriptor: Descriptor which value will be read.
     */
    public func readValueForDescriptor(descriptor: RxDescriptorType) {
        peripheral.readValueForDescriptor((descriptor as! RxCBDescriptor).descriptor)
    }

    /**
     Write value to descriptor. Results will be available in `rx_didWriteValueForDescriptor` observable after
     subscription.

     - parameter data: Data to be write to descriptor.
     - parameter forDescriptor: Descriptor which value will be written.
     */
    public func writeValue(data: NSData, forDescriptor descriptor: RxDescriptorType) {
        peripheral.writeValue(data, forDescriptor: (descriptor as! RxCBDescriptor).descriptor)
    }

    /// Read RSSI from peripheral
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
        let peripheralDidUpdateNotificationStateForCharacteristicSubject =
            PublishSubject<(RxCharacteristicType, NSError?)>()
        let peripheralDidDiscoverDescriptorsForCharacteristicSubject =
            PublishSubject<(RxCharacteristicType, NSError?)>()
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

        @objc func peripheral(peripheral: CBPeripheral,
                              didDiscoverIncludedServicesForService service: CBService,
                              error: NSError?) {
            peripheralDidDiscoverIncludedServicesForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didDiscoverCharacteristicsForService service: CBService,
                              error: NSError?) {
            peripheralDidDiscoverCharacteristicsForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                              error: NSError?) {
            peripheralDidUpdateValueForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didWriteValueForCharacteristic characteristic: CBCharacteristic,
                              error: NSError?) {
            peripheralDidWriteValueForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic,
                              error: NSError?) {
            peripheralDidUpdateNotificationStateForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic,
                              error: NSError?) {
            peripheralDidDiscoverDescriptorsForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didUpdateValueForDescriptor descriptor: CBDescriptor,
                              error: NSError?) {
            peripheralDidUpdateValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }

        @objc func peripheral(peripheral: CBPeripheral,
                              didWriteValueForDescriptor descriptor: CBDescriptor,
                              error: NSError?) {
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
