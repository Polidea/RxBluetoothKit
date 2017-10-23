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

class RxCBPeripheral: RxPeripheralType {

    let peripheral: CBPeripheral
    private let internalDelegate: InternalPeripheralDelegate

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        internalDelegate = RxCBPeripheral.getInternalPeripheralDelegateRef(cbPeripheral: peripheral)
    }

    deinit {
        RxCBPeripheral.putInternalPeripheralDelegateRef(cbPeripheral: peripheral)
    }

    var identifier: UUID {
        return peripheral.value(forKey: "identifier") as! NSUUID as UUID
    }

    @available(*, deprecated)
    var objectId: UInt {
        return UInt(bitPattern: ObjectIdentifier(peripheral))
    }

    var name: String? {
        return peripheral.name
    }

    var state: CBPeripheralState {
        return peripheral.state
    }

    var services: [RxServiceType]? {
        return peripheral.services?.map(RxCBService.init)
    }

    /// `Observable` which emits peripheral's name changes
    var rx_didUpdateName: Observable<String?> {
        return internalDelegate.peripheralDidUpdateNameSubject
    }

    /// `Observable` which emits when service's are modified
    var rx_didModifyServices: Observable<([RxServiceType])> {
        return internalDelegate.peripheralDidModifyServicesSubject
    }

    /// `Observable` which emits when RSSI was read
    var rx_didReadRSSI: Observable<(Int, Error?)> {
        return internalDelegate.peripheralDidReadRSSISubject
    }

    /// `Observable` which emits discovered serivices during discovery
    var rx_didDiscoverServices: Observable<([RxServiceType]?, Error?)> {
        return internalDelegate.peripheralDidDiscoverServicesSubject
    }

    /// `Observable` which emits service for which included services were discovered
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, Error?)> {
        return internalDelegate.peripheralDidDiscoverIncludedServicesForServiceSubject
    }

    /// `Observable` which emits service for which characteristics were discovered
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, Error?)> {
        return internalDelegate.peripheralDidDiscoverCharacteristicsForServiceSubject
    }

    /// `Observable` which emits characteristic which value has been updated
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidUpdateValueForCharacteristicSubject
    }

    /// `Observable` which emits characteristic for which value was written successfully
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidWriteValueForCharacteristicSubject
    }

    /// `Observable` which emits characteristic which notification value was successfully modified
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidUpdateNotificationStateForCharacteristicSubject
    }

    /// `Observable` which emits characteristic for which descriptors were discovered
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, Error?)> {
        return internalDelegate.peripheralDidDiscoverDescriptorsForCharacteristicSubject
    }

    /// `Observable` which emits descriptor which value was updated
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, Error?)> {
        return internalDelegate.peripheralDidUpdateValueForDescriptorSubject
    }

    /// `Observable` which emits descriptor which completed sucessfully its write operation
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, Error?)> {
        return internalDelegate.peripheralDidWriteValueForDescriptorSubject
    }

    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: RxServiceType) {
        peripheral.discoverCharacteristics(characteristicUUIDs, for: (service as! RxCBService).service)
    }

    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: RxServiceType) {
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: (service as! RxCBService).service)
    }

    func readValue(for characteristic: RxCharacteristicType) {
        peripheral.readValue(for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    func writeValue(_ data: Data,
                    for characteristic: RxCharacteristicType,
                    type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: (characteristic as! RxCBCharacteristic).characteristic,
                              type: type)
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: RxCharacteristicType) {
        peripheral.setNotifyValue(enabled, for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    func discoverDescriptors(for characteristic: RxCharacteristicType) {
        peripheral.discoverDescriptors(for: (characteristic as! RxCBCharacteristic).characteristic)
    }

    func readValue(for descriptor: RxDescriptorType) {
        peripheral.readValue(for: (descriptor as! RxCBDescriptor).descriptor)
    }

    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }

    func writeValue(_ data: Data, for descriptor: RxDescriptorType) {
        peripheral.writeValue(data, for: (descriptor as! RxCBDescriptor).descriptor)
    }

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
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didUpdateName(name: \(String(describing: peripheral.name)))
                                """)
            peripheralDidUpdateNameSubject.onNext(peripheral.name)
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didModifyServices(services:
                                [\(invalidatedServices.logDescription))]
                                """)
            peripheralDidModifyServicesSubject.onNext(invalidatedServices.map(RxCBService.init))
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didReadRSSI rssi: NSNumber, error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didReadRSSI(rssi: \(rssi),
                                error: \(String(describing: error)))
                                """)
            peripheralDidReadRSSISubject.onNext((rssi.intValue, error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didDiscoverServices(services
                                : \(String(describing: peripheral.services?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidDiscoverServicesSubject.onNext((peripheral.services?.map(RxCBService.init), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didDiscoverIncludedServicesFor service: CBService,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didDiscoverIncludedServices(for:
                                \(service.logDescription), includedServices:
                                \(String(describing: service.includedServices?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidDiscoverIncludedServicesForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didDiscoverCharacteristicsFor service: CBService,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didDiscoverCharacteristicsFor(for:
                                \(service.logDescription), characteristics:
                                \(String(describing: service.characteristics?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidDiscoverCharacteristicsForServiceSubject.onNext((RxCBService(service: service), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didUpdateValueFor characteristic: CBCharacteristic,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didUpdateValueFor(for:\(characteristic.logDescription),
                                value: \(String(describing: characteristic.value?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidUpdateValueForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didWriteValueFor characteristic: CBCharacteristic,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didWriteValueFor(for:\(characteristic.logDescription),
                                value: \(String(describing: characteristic.value?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidWriteValueForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didUpdateNotificationStateFor characteristic: CBCharacteristic,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didUpdateNotificationStateFor(
                                for:\(characteristic.logDescription), isNotifying: \(characteristic.isNotifying),
                                error: \(String(describing: error)))
                                """)
            peripheralDidUpdateNotificationStateForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didDiscoverDescriptorsFor
                                (for:\(characteristic.logDescription), descriptors:
                                \(String(describing: characteristic.descriptors?.logDescription)),
                                error: \(String(describing: error)))
                                """)
            peripheralDidDiscoverDescriptorsForCharacteristicSubject
                .onNext((RxCBCharacteristic(characteristic: characteristic), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didUpdateValueFor descriptor: CBDescriptor,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didUpdateValueFor(for:\(descriptor.logDescription),
                                value: \(String(describing: descriptor.value)), error: \(String(describing: error)))
                                """)
            peripheralDidUpdateValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }

        @objc func peripheral(_ peripheral: CBPeripheral,
                              didWriteValueFor descriptor: CBDescriptor,
                              error: Error?) {
            RxBluetoothKitLog.d("""
                                \(peripheral.logDescription) didWriteValueFor(for:\(descriptor.logDescription),
                                error: \(String(describing: error)))
                                """)
            peripheralDidWriteValueForDescriptorSubject.onNext((RxCBDescriptor(descriptor: descriptor), error))
        }
    }

    fileprivate class InternalPeripheralDelegateWrapper {
        fileprivate let delegate: InternalPeripheralDelegate
        fileprivate var refCount: Int

        fileprivate init(delegate: InternalPeripheralDelegate) {
            self.delegate = delegate
            refCount = 1
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
