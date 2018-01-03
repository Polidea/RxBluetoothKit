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
@testable import RxBluetoothKit
import RxSwift

class _CBPeripheralDelegateWrapper: NSObject, _CBPeripheralDelegate {

    let peripheralDidUpdateName = PublishSubject<String?>()
    let peripheralDidModifyServices = PublishSubject<([CBServiceMock])>()
    let peripheralDidReadRSSI = PublishSubject<(Int, Error?)>()
    let peripheralDidDiscoverServices = PublishSubject<([CBServiceMock]?, Error?)>()
    let peripheralDidDiscoverIncludedServicesForService = PublishSubject<(CBServiceMock, Error?)>()
    let peripheralDidDiscoverCharacteristicsForService = PublishSubject<(CBServiceMock, Error?)>()
    let peripheralDidUpdateValueForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    let peripheralDidWriteValueForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    let peripheralDidUpdateNotificationStateForCharacteristic =
        PublishSubject<(CBCharacteristicMock, Error?)>()
    let peripheralDidDiscoverDescriptorsForCharacteristic =
        PublishSubject<(CBCharacteristicMock, Error?)>()
    let peripheralDidUpdateValueForDescriptor = PublishSubject<(CBDescriptorMock, Error?)>()
    let peripheralDidWriteValueForDescriptor = PublishSubject<(CBDescriptorMock, Error?)>()
    let peripheralIsReadyToSendWriteWithoutResponse = PublishSubject<Void>()
    let peripheralDidOpenL2CAPChannel = PublishSubject<(Any?, Error?)>()

    func peripheralDidUpdateName(_ peripheral: CBPeripheralMock) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateName(name: \(String(describing: peripheral.name)))
            """)
        peripheralDidUpdateName.onNext(peripheral.name)
    }

    func peripheral(_ peripheral: CBPeripheralMock, didModifyServices invalidatedServices: [CBServiceMock]) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didModifyServices(services:
            [\(invalidatedServices.logDescription))]
            """)
        peripheralDidModifyServices.onNext(invalidatedServices)
    }

    func peripheral(_ peripheral: CBPeripheralMock, didReadRSSI rssi: NSNumber, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didReadRSSI(rssi: \(rssi),
            error: \(String(describing: error)))
            """)
        peripheralDidReadRSSI.onNext((rssi.intValue, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock, didDiscoverServices error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverServices(services
            : \(String(describing: peripheral.services?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverServices.onNext((peripheral.services, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didDiscoverIncludedServicesFor service: CBServiceMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverIncludedServices(for:
            \(service.logDescription), includedServices:
            \(String(describing: service.includedServices?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverIncludedServicesForService.onNext((service, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didDiscoverCharacteristicsFor service: CBServiceMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverCharacteristicsFor(for:
            \(service.logDescription), characteristics:
            \(String(describing: service.characteristics?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverCharacteristicsForService.onNext((service, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didUpdateValueFor characteristic: CBCharacteristicMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateValueFor(for:\(characteristic.logDescription),
            value: \(String(describing: characteristic.value?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidUpdateValueForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didWriteValueFor characteristic: CBCharacteristicMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didWriteValueFor(for:\(characteristic.logDescription),
            value: \(String(describing: characteristic.value?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidWriteValueForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didUpdateNotificationStateFor characteristic: CBCharacteristicMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateNotificationStateFor(
            for:\(characteristic.logDescription), isNotifying: \(characteristic.isNotifying),
            error: \(String(describing: error)))
            """)
        peripheralDidUpdateNotificationStateForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristicMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverDescriptorsFor
            (for:\(characteristic.logDescription), descriptors:
            \(String(describing: characteristic.descriptors?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverDescriptorsForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didUpdateValueFor descriptor: CBDescriptorMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateValueFor(for:\(descriptor.logDescription),
            value: \(String(describing: descriptor.value)), error: \(String(describing: error)))
            """)
        peripheralDidUpdateValueForDescriptor.onNext((descriptor, error))
    }

    func peripheral(_ peripheral: CBPeripheralMock,
                    didWriteValueFor descriptor: CBDescriptorMock,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didWriteValueFor(for:\(descriptor.logDescription),
            error: \(String(describing: error)))
            """)
        peripheralDidWriteValueForDescriptor.onNext((descriptor, error))
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheralMock) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) peripheralIsReady(toSendWriteWithoutResponse)
            """)
        peripheralIsReadyToSendWriteWithoutResponse.onNext(())
    }

    @available(OSX 10.13, iOS 11, *)
    func peripheral(_ peripheral: CBPeripheralMock, didOpen channel: CBL2CAPChannelMock?, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didOpenL2CAPChannel(for:\(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        peripheralDidOpenL2CAPChannel.onNext((channel, error))
    }

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheralMock, error: Error?) {}
}
