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
import RxTest
@testable
import RxBluetoothKit

class FakePeripheral: RxPeripheralType {


    var name: String? = nil
    var state: CBPeripheralState = CBPeripheralState.connected
    var rx_state: Observable<CBPeripheralState> = .never()
    var services: [RxServiceType]? = nil
    var identifier: UUID = UUID()
    var maximumWriteValueLength = 0

    var RSSI: Int? = nil


    var rx_didUpdateName: Observable<String?> = .never()
    var rx_didModifyServices: Observable<[RxServiceType]> = .never()
    var rx_didReadRSSI: Observable<(Int, Error?)> = .never()
    var rx_didDiscoverServices: Observable<([RxServiceType]?, Error?)> = .never()
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, Error?)> = .never()
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, Error?)> = .never()
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> = .never()
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> = .never()
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, Error?)> = .never()
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, Error?)> = .never()
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, Error?)> = .never()
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, Error?)> = .never()


    var discoverServicesTO: TestableObserver<[CBUUID]?>?
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesTO?.onNext(serviceUUIDs)
    }

    var discoverCharacteristicsTO: TestableObserver<([CBUUID]?, RxServiceType)>?
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for forService: RxServiceType) {
        discoverCharacteristicsTO?.onNext((characteristicUUIDs, forService))
    }

    var discoverIncludedServicesTO: TestableObserver<([CBUUID]?, RxServiceType)>?
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: RxServiceType) {
        discoverIncludedServicesTO?.onNext((includedServiceUUIDs, service))
    }

    var readValueForCharacteristicTO: TestableObserver<RxCharacteristicType>?
    func readValue(for characteristic: RxCharacteristicType) {
        readValueForCharacteristicTO?.onNext(characteristic)
    }

    @available(OSX 10.12, iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return maximumWriteValueLength
    }

    var writeValueForCharacteristicTypeTO: TestableObserver<(Data, RxCharacteristicType, CBCharacteristicWriteType)>?
    func writeValue(_ data: Data, for characteristic: RxCharacteristicType, type: CBCharacteristicWriteType) {
        writeValueForCharacteristicTypeTO?.onNext((data, characteristic, type))
    }

    var setNotifyValueForCharacteristicTO: TestableObserver<(Bool, RxCharacteristicType)>?
    func setNotifyValue(_ enabled: Bool, for characteristic: RxCharacteristicType) {
        setNotifyValueForCharacteristicTO?.onNext((enabled, characteristic))
    }

    var discoverDescriptorsForCharacteristicTO: TestableObserver<RxCharacteristicType>?
    func discoverDescriptors(for characteristic: RxCharacteristicType) {
        discoverDescriptorsForCharacteristicTO?.onNext(characteristic)
    }

    var readValueForDescriptorTO: TestableObserver<RxDescriptorType>?
    func readValue(for descriptor: RxDescriptorType) {
        readValueForDescriptorTO?.onNext(descriptor)
    }
    var writeValueForDescriptorTO: TestableObserver<(Data, RxDescriptorType)>?
    func writeValue(_ data: Data, for descriptor: RxDescriptorType) {
        writeValueForDescriptorTO?.onNext((data, descriptor))
    }
    var readRSSITO: TestableObserver<Void>?
    func readRSSI() {
        readRSSITO?.onNext()
    }
}
