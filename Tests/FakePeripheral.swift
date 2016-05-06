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
import RxSwift
import CoreBluetooth
import RxTests
@testable
import RxBluetoothKit

class FakePeripheral: RxPeripheralType {


    var name: String? = nil
    var state: CBPeripheralState = CBPeripheralState.Connected
    var rx_state: Observable<CBPeripheralState> = .never()
    var services: [RxServiceType]? = nil
    var identifier: NSUUID = NSUUID()

    var RSSI: Int? = nil


    var rx_didUpdateName: Observable<String?> = .never()
    var rx_didModifyServices: Observable<[RxServiceType]> = .never()
    var rx_didReadRSSI: Observable<(Int, NSError?)> = .never()
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
