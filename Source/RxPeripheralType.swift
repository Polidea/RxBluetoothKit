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

protocol RxPeripheralType {

    var name: String? { get }

    var identifier: UUID { get }

    @available(*, deprecated)
    var objectId: UInt { get }

    var peripheral: CBPeripheral { get }

    var state: CBPeripheralState { get }

    var services: [RxServiceType]? { get }

    /// `Observable` which emits peripheral's name changes
    var rx_didUpdateName: Observable<String?> { get }

    /// `Observable` which emits when service's are modified
    var rx_didModifyServices: Observable<([RxServiceType])> { get }

    /// `Observable` which emits when RSSI was read
    var rx_didReadRSSI: Observable<(Int, Error?)> { get }

    /// `Observable` which emits discovered serivices during discovery
    var rx_didDiscoverServices: Observable<([RxServiceType]?, Error?)> { get }

    /// `Observable` which emits service for which included services were discovered
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, Error?)> { get }

    /// `Observable` which emits service for which characteristics were discovered
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, Error?)> { get }

    /// `Observable` which emits characteristic which value has been updated
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// `Observable` which emits characteristic for which value was written successfully
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// `Observable` which emits characteristic which notification value was successfully modified
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// `Observable` which emits characteristic for which descriptors were discovered
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// `Observable` which emits descriptor which value was updated
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, Error?)> { get }

    /// `Observable` which emits descriptor which completed sucessfully its write operation
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, Error?)> { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: RxServiceType)

    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: RxServiceType)

    func readValue(for characteristic: RxCharacteristicType)

    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

    func writeValue(_ data: Data,
                    for characteristic: RxCharacteristicType,
                    type: CBCharacteristicWriteType)

    func setNotifyValue(_ enabled: Bool, for characteristic: RxCharacteristicType)

    func discoverDescriptors(for characteristic: RxCharacteristicType)

    func readValue(for descriptor: RxDescriptorType)

    func writeValue(_ data: Data, for descriptor: RxDescriptorType)

    func readRSSI()
}

extension Equatable where Self: RxPeripheralType {}

func == (lhs: RxPeripheralType, rhs: RxPeripheralType) -> Bool {
    return lhs.identifier == rhs.identifier
}
