// The MIT License (MIT)
//
// Copyright (c) 2017 Polidea
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

@objc class CBPeripheralDelegateWrapper: NSObject, CBPeripheralDelegate {

    var rx_didUpdateName: Observable<String?> { return peripheralDidUpdateNameSubject }
    var rx_didModifyServices: Observable<([CBService])> { return peripheralDidModifyServicesSubject }
    var rx_didReadRSSI: Observable<(Int, Error?)> { return peripheralDidReadRSSISubject }
    var rx_didDiscoverServices: Observable<([CBService]?, Error?)> { return peripheralDidDiscoverServicesSubject }
    var rx_didDiscoverIncludedServicesForService: Observable<(CBService, Error?)> {
        return peripheralDidDiscoverIncludedServicesForServiceSubject
    }
    var rx_didDiscoverCharacteristicsForService: Observable<(CBService, Error?)> {
        return peripheralDidDiscoverCharacteristicsForServiceSubject
    }
    var rx_didUpdateValueForCharacteristic: Observable<(CBCharacteristic, Error?)> {
        return peripheralDidUpdateValueForCharacteristicSubject
    }
    var rx_didWriteValueForCharacteristic: Observable<(CBCharacteristic, Error?)> {
        return peripheralDidWriteValueForCharacteristicSubject
    }
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(CBCharacteristic, Error?)> {
        return peripheralDidUpdateNotificationStateForCharacteristicSubject
    }
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(CBCharacteristic, Error?)> {
        return peripheralDidDiscoverDescriptorsForCharacteristicSubject
    }
    var rx_didUpdateValueForDescriptor: Observable<(CBDescriptor, Error?)> {
        return peripheralDidUpdateValueForDescriptorSubject
    }
    var rx_didWriteValueForDescriptor: Observable<(CBDescriptor, Error?)> {
        return peripheralDidWriteValueForDescriptorSubject
    }
    var rx_peripheralReadyToSendWriteWithoutResponse: Observable<Void> {
        return peripheralIsReadyToSendWriteWithoutResponseSubject
    }

    private let peripheralDidUpdateNameSubject = PublishSubject<String?>()
    private let peripheralDidModifyServicesSubject = PublishSubject<([CBService])>()
    private let peripheralDidReadRSSISubject = PublishSubject<(Int, Error?)>()
    private let peripheralDidDiscoverServicesSubject = PublishSubject<([CBService]?, Error?)>()
    private let peripheralDidDiscoverIncludedServicesForServiceSubject = PublishSubject<(CBService, Error?)>()
    private let peripheralDidDiscoverCharacteristicsForServiceSubject = PublishSubject<(CBService, Error?)>()
    private let peripheralDidUpdateValueForCharacteristicSubject = PublishSubject<(CBCharacteristic, Error?)>()
    private let peripheralDidWriteValueForCharacteristicSubject = PublishSubject<(CBCharacteristic, Error?)>()
    private let peripheralDidUpdateNotificationStateForCharacteristicSubject =
        PublishSubject<(CBCharacteristic, Error?)>()
    private let peripheralDidDiscoverDescriptorsForCharacteristicSubject =
        PublishSubject<(CBCharacteristic, Error?)>()
    private let peripheralDidUpdateValueForDescriptorSubject = PublishSubject<(CBDescriptor, Error?)>()
    private let peripheralDidWriteValueForDescriptorSubject = PublishSubject<(CBDescriptor, Error?)>()
    private let peripheralIsReadyToSendWriteWithoutResponseSubject = PublishSubject<Void>()

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
        peripheralDidModifyServicesSubject.onNext(invalidatedServices)
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
        peripheralDidDiscoverServicesSubject.onNext((peripheral.services, error))
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
        peripheralDidDiscoverIncludedServicesForServiceSubject.onNext((service, error))
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
        peripheralDidDiscoverCharacteristicsForServiceSubject.onNext((service, error))
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
            .onNext((characteristic, error))
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
            .onNext((characteristic, error))
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
            .onNext((characteristic, error))
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
            .onNext((characteristic, error))
    }

    @objc func peripheral(_ peripheral: CBPeripheral,
                          didUpdateValueFor descriptor: CBDescriptor,
                          error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateValueFor(for:\(descriptor.logDescription),
            value: \(String(describing: descriptor.value)), error: \(String(describing: error)))
            """)
        peripheralDidUpdateValueForDescriptorSubject.onNext((descriptor, error))
    }

    @objc func peripheral(_ peripheral: CBPeripheral,
                          didWriteValueFor descriptor: CBDescriptor,
                          error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didWriteValueFor(for:\(descriptor.logDescription),
            error: \(String(describing: error)))
            """)
        peripheralDidWriteValueForDescriptorSubject.onNext((descriptor, error))
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) peripheralIsReady(toSendWriteWithoutResponse)
            """)
        peripheralIsReadyToSendWriteWithoutResponseSubject.onNext(())
    }
}
