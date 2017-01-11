// The MIT License (MIT)
//
// Copyright (c) 2016 Polidea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import CoreBluetooth
import RxSwift

/**
 Core Bluetooth implementation of RxPeripheralType. This is a lightweight wrapper which allows
 to hide all implementation details.
 */
class RxCBPeripheral: RxPeripheralType {

    let peripheral: CBPeripheral
    private let internalDelegate: InternalPeripheralDelegate

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.internalDelegate = RxCBPeripheral.getInternalPeripheralDelegateRef(cbPeripheral: peripheral)
    }

    deinit {
        RxCBPeripheral.putInternalPeripheralDelegateRef(cbPeripheral: peripheral)
    }

    /// Peripheral's identifier
    var identifier: UUID {
        return peripheral.identifier
    }

    /// Peripheral's name
    var name: String? {
        return peripheral.name
    }

    /// Peripheral's state
    var state: CBPeripheralState {
        return peripheral.state
    }

    /// Peripheral's services
    var services: [RxServiceType]? {
        return peripheral.services?.map { RxCBService(service: $0) }
    }

    /// Observable which emits peripheral's name changes
    var rx_didUpdateName: Observable<String?> {
        return internalDelegate.peripheralDidUpdateNameSubject
    }

    /// Observable which emits when service's are modified
    var rx_didModifyServices: Observable<([RxServiceType])> {
        return internalDelegate.peripheralDidModifyServicesSubject
    }

    /// Observable which emits when RSSI was read
    var rx_didReadRSSI: Observable<(Int, Error?)> {
        return internalDelegate.peripheralDidReadRSSISubject
    }

    /// Observable which emits discovered serivices during discovery
    var rx_didDiscoverServices: Observable<([RxServiceType]?, Error?)> {
        return internalDelegate.peripheralDidDiscoverServicesSubject
    }

    /// Observable which emits service for which included services were discovered
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, Error?)> {
        return internalDelegate.peripheralDidDiscoverIncludedServicesForServiceSubject
    }

    /// Observable which emits service for which characteristics were discovered
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, Error?)> {
        return internalDelegate.peripheralDidDiscoverCharacteristicsForServiceSubject
    }

    /// Observable which emits characteristic which value has been updated
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidUpdateValueForCharacteristicSubject
    }

    /// Observable which emits characteristic for which value was written successfully
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidWriteValueForCharacteristicSubject
    }

    /// Observable which emits characteristic which notification value was successfully modified
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidUpdateNotificationStateForCharacteristicSubject
    }

    /// Observable which emits characteristic for which descriptors were discovered
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidDiscoverDescriptorsForCharacteristicSubject
    }

    /// Observable which emits descriptor which value was updated
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, Error?)> {
        return internalDelegate.peripheralDidUpdateValueForDescriptorSubject
    }

    /// Observable which emits descriptor which completed sucessfully its write operation
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, Error?)> {
        return internalDelegate.peripheralDidWriteValueForDescriptorSubject
    }

    /**
     Discover services with specified optional list of UUIDs. Passing `nil` will show all available services for
     peripheral. Results are returned by `rx_didDiscoverServices` observable after subscription.

     - parameter serviceUUIDs: List of UUIDS which must be implemented by a peripheral
     */
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }

    /**
     Discover characteristics for peripheral's service. If list is passed only characteristics with certain UUID are
     returned during discovery, otherwise all characteristics will be discovered for certain service. Results are
     returned by `rx_didDiscoverCharacteristicsForService` observable after subscription.

     - parameter characteristicUUIDs: List of UUIDs of characteristics which should be returned.
     - parameter forService: Serivce which includes characteristics
     */
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: RxServiceType) {
        peripheral.discoverCharacteristics(characteristicUUIDs, for: (service as! RxCBService).service)
    }

    /**
     Discover included services inside of another service. Values are returned
     by `rx_didDiscoverIncludedServicesForService` observable which emits retults of this call after subscription.

     - parameter includedServiceUUIDs: List of included serive's UUID for which we are looking for. If `nil` is passed
     all included services will be discovered
     - parameter forService: Service which contains included services.
     */
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: RxServiceType) {
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: (service as! RxCBService).service)
    }

    /**
     Read value for characteristic. Result will be available in `rx_didUpdateValueForCharacteristic` observable after
     subscibe.
     - parameter characteristic: Characteristic from which we are reading
     */
    func readValue(for characteristic: RxCharacteristicType) {
        peripheral.readValue(for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Write value to characteristic. Confirmation that characteristic was read will be available in
     `rx_didWriteValueForCharacteristic` observable after subscribe.
     - parameter data: Data which will be written in characteristic
     - parameter forCharacteristic: Characteristic to which new value will be written.
     - parameter type: Type of write operation
     */
    func writeValue(_ data: Data,
        for characteristic: RxCharacteristicType,
        type: CBCharacteristicWriteType) {
            peripheral.writeValue(data, for: (characteristic as! RxCBCharacteristic).characteristic,
                type: type)
    }

    /**
     Set if notifications for characteristic value changes should be monitored on `rx_didUpdateValueForCharacteristic`
     - parameter enabled: True if notifications for value changes should be enabled
     - parameter forCharacteristic: Characteristic for which notifications will be enabled or disabled
     */
    func setNotifyValue(_ enabled: Bool, for characteristic: RxCharacteristicType) {
        peripheral.setNotifyValue(enabled, for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Discover descriptors for specific characteristic. Successful operation will be indicated in
     `rx_didDiscoverDescriptorsForCharacteristic` observable in subscription.

     - parameter characteristic: Characteristic for which descriptors will be discovered
     */
    func discoverDescriptors(for characteristic: RxCharacteristicType) {
        peripheral.discoverDescriptors(for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    /**
     Read value for descriptor. Results will be available in `rx_didUpdateValueForDescriptor` observable after
     subscription.

     - parameter descriptor: Descriptor which value will be read.
     */
    func readValue(for descriptor: RxDescriptorType) {
        peripheral.readValue(for: (descriptor as! RxCBDescriptor).descriptor)
    }

    /*!
     *  @method		maximumWriteValueLengthForType:
     *
     *  @discussion	The maximum amount of data, in bytes, that can be sent to a characteristic in a single write type.
     *
     *  @see		writeValue:forCharacteristic:type:
     */
    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }

    /**
     Write value to descriptor. Results will be available in `rx_didWriteValueForDescriptor` observable after
     subscription.

     - parameter data: Data to be write to descriptor.
     - parameter forDescriptor: Descriptor which value will be written.
     */
    func writeValue(_ data: Data, for descriptor: RxDescriptorType) {
        peripheral.writeValue(data, for: (descriptor as! RxCBDescriptor).descriptor)
    }

    /// Read RSSI from peripheral
    func readRSSI() {
        peripheral.readRSSI()
    }

    @objc fileprivate class InternalPeripheralDelegate: NSObject, CBPeripheralDelegate {
        let peripheralDidUpdateNameSubject = PublishSubject<String?>()
        let peripheralDidModifyServicesSubject = PublishSubject<([RxServiceType])>()
        let peripheralDidReadRSSISubject = PublishSubject<(Int, Error?)>()
        let peripheralDidDiscoverServicesSubject = PublishSubject<([RxServiceType]?, Error?)>()
        let peripheralDidDiscoverIncludedServicesForServiceSubject = PublishSubject<(RxServiceType, Error?)>()
        let peripheralDidDiscoverCharacteristicsForServiceSubject = PublishSubject<(RxServiceType, Error?)>()
        let peripheralDidUpdateValueForCharacteristicSubject = PublishSubject<(RxCharacteristicType, Error?)>()
        let peripheralDidWriteValueForCharacteristicSubject = PublishSubject<(RxCharacteristicType, Error?)>()
        let peripheralDidUpdateNotificationStateForCharacteristicSubject =
            PublishSubject<(RxCharacteristicType, Error?)>()
        let peripheralDidDiscoverDescriptorsForCharacteristicSubject =
            PublishSubject<(RxCharacteristicType, Error?)>()
        let peripheralDidUpdateValueForDescriptorSubject = PublishSubject<(RxDescriptorType, Error?)>()
        let peripheralDidWriteValueForDescriptorSubject = PublishSubject<(RxDescriptorType, Error?)>()

        @objc func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            peripheralDidUpdateNameSubject.onNext(peripheral.name)
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
            peripheralDidModifyServicesSubject.onNext(invalidatedServices.map {
                RxCBService(service: $0)
            })
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didReadRSSI rssi: NSNumber, error: Error?) {
            peripheralDidReadRSSISubject.onNext((rssi.intValue, error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            peripheralDidDiscoverServicesSubject.onNext((peripheral.services?.map {
                RxCBService(service: $0)
                }, error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didDiscoverIncludedServicesFor service: CBService,
            error: Error?) {
                peripheralDidDiscoverIncludedServicesForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?) {
                peripheralDidDiscoverCharacteristicsForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didUpdateValueFor characteristic: CBCharacteristic,
            error: Error?) {
                peripheralDidUpdateValueForCharacteristicSubject
                    .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?) {
                peripheralDidWriteValueForCharacteristicSubject
                    .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didUpdateNotificationStateFor characteristic: CBCharacteristic,
            error: Error?) {
                peripheralDidUpdateNotificationStateForCharacteristicSubject
                    .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didDiscoverDescriptorsFor characteristic: CBCharacteristic,
            error: Error?) {
                peripheralDidDiscoverDescriptorsForCharacteristicSubject
                    .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didUpdateValueFor descriptor: CBDescriptor,
            error: Error?) {
                peripheralDidUpdateValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
            didWriteValueFor descriptor: CBDescriptor,
            error: Error?) {
                peripheralDidWriteValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }
    }

    fileprivate class InternalPeripheralDelegateWrapper {
        fileprivate let delegate: InternalPeripheralDelegate
        fileprivate var refCount: Int

        fileprivate init(delegate: InternalPeripheralDelegate) {
            self.delegate = delegate
            self.refCount = 1
        }
    }

    private static let internalPeripheralDelegateWrappersLock = NSLock()
    private static var internalPeripheralDelegateWrappers = [CBPeripheral: InternalPeripheralDelegateWrapper]()

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

    fileprivate static func putInternalPeripheralDelegateRef(cbPeripheral: CBPeripheral) {
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
