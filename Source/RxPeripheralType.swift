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

/**
 Protocol which wraps bluetooth peripheral.
 */
protocol RxPeripheralType {

    /// Peripheral's name
    var name: String? { get }

    /// Peripheral's identifier
    var identifier: UUID { get }

    /// Peripheral's state
    var state: CBPeripheralState { get }

    /// Peripheral's services
    var services: [RxServiceType]? { get }

    /// Observable which emits peripheral's name changes
    var rx_didUpdateName: Observable<String?> { get }

    /// Observable which emits when service's are modified
    var rx_didModifyServices: Observable<([RxServiceType])> { get }

    /// Observable which emits when RSSI was read
    var rx_didReadRSSI: Observable<(Int, Error?)> { get }

    /// Observable which emits discovered serivices during discovery
    var rx_didDiscoverServices: Observable<([RxServiceType]?, Error?)> { get }

    /// Observable which emits service for which included services were discovered
    var rx_didDiscoverIncludedServicesForService: Observable<(RxServiceType, Error?)> { get }

    /// Observable which emits service for which characteristics were discovered
    var rx_didDiscoverCharacteristicsForService: Observable<(RxServiceType, Error?)> { get }

    /// Observable which emits characteristic which value has been updated
    var rx_didUpdateValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// Observable which emits characteristic for which value was written successfully
    var rx_didWriteValueForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// Observable which emits characteristic which notification value was successfully modified
    var rx_didUpdateNotificationStateForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// Observable which emits characteristic for which descriptors were discovered
    var rx_didDiscoverDescriptorsForCharacteristic: Observable<(RxCharacteristicType, Error?)> { get }

    /// Observable which emits descriptor which value was updated
    var rx_didUpdateValueForDescriptor: Observable<(RxDescriptorType, Error?)> { get }

    /// Observable which emits descriptor which completed sucessfully its write operation
    var rx_didWriteValueForDescriptor: Observable<(RxDescriptorType, Error?)> { get }

    /**
     Discover services with specified optional list of UUIDs. Passing `nil` will show all available services for
     peripheral. Results are returned by `rx_didDiscoverServices` observable after subscription.

     - parameter serviceUUIDs: List of UUIDS which must be implemented by a peripheral
     */
    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    /**
     Discover characteristics for peripheral's service. If list is passed only characteristics with certain UUID are
     returned during discovery, otherwise all characteristics will be discovered for certain service. Results are
     returned by `rx_didDiscoverCharacteristicsForService` observable after subscription.

     - parameter characteristicUUIDs: List of UUIDs of characteristics which should be returned.
     - parameter forService: Serivce which includes characteristics
     */
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: RxServiceType)

    /**
     Discover included services inside of another service. Values are returned
     by `rx_didDiscoverIncludedServicesForService` observable which emits retults of this call after subscription.

     - parameter includedServiceUUIDs: List of included serive's UUID for which we are looking for. If `nil` is passed
     all included services will be discovered
     - parameter forService: Service which contains included services.
     */
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: RxServiceType)

    /**
     Read value for characteristic. Result will be available in `rx_didUpdateValueForCharacteristic` observable after
     subscibe.
     - parameter characteristic: Characteristic from which we are reading
     */
    func readValue(for characteristic: RxCharacteristicType)

    /*!
     *  @method		maximumWriteValueLengthForType:
     *
     *  @discussion	The maximum amount of data, in bytes, that can be sent to a characteristic in a single write type.
     *
     *  @see		writeValue:forCharacteristic:type:
     */
    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

    /**
     Write value to characteristic. Confirmation that characteristic was read will be available in
     `rx_didWriteValueForCharacteristic` observable after subscribe.
     - parameter data: Data which will be written in characteristic
     - parameter forCharacteristic: Characteristic to which new value will be written.
     - parameter type: Type of write operation
     */
    func writeValue(_ data: Data,
                    for characteristic: RxCharacteristicType,
                    type: CBCharacteristicWriteType)

    /**
     Set if notifications for characteristic value changes should be monitored on `rx_didUpdateValueForCharacteristic`
     - parameter enabled: True if notifications for value changes should be enabled
     - parameter forCharacteristic: Characteristic for which notifications will be enabled or disabled
     */
    func setNotifyValue(_ enabled: Bool, for characteristic: RxCharacteristicType)

    /**
     Discover descriptors for specific characteristic. Successful operation will be indicated in
     `rx_didDiscoverDescriptorsForCharacteristic` observable in subscription.

     - parameter characteristic: Characteristic for which descriptors will be discovered
     */
    func discoverDescriptors(for characteristic: RxCharacteristicType)

    /**
     Read value for descriptor. Results will be available in `rx_didUpdateValueForDescriptor` observable after
     subscription.

     - parameter descriptor: Descriptor which value will be read.
     */
    func readValue(for descriptor: RxDescriptorType)

    /**
     Write value to descriptor. Results will be available in `rx_didWriteValueForDescriptor` observable after
     subscription.

     - parameter data: Data to be write to descriptor.
     - parameter forDescriptor: Descriptor which value will be written.
     */
    func writeValue(_ data: Data, for descriptor: RxDescriptorType)

    /// Read RSSI from peripheral
    func readRSSI()

}

extension Equatable where Self: RxPeripheralType {}

/**
 Compares two peripherals. They are equal when theirs identifiers are the same.

 - parameter lhs: First peripheral
 - parameter rhs: Second peripheral
 - returns: True if both peripherals are the same.
 */
func == (lhs: RxPeripheralType, rhs: RxPeripheralType) -> Bool {
    return lhs.identifier == rhs.identifier
}
