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
import RxSwift
import CoreBluetooth

// swiftlint:disable line_length

/// Characteristic is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with [CBCharacteristic](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/)
public class Characteristic {
    /// Intance of CoreBluetooth characteristic class
    public let characteristic: CBCharacteristic

    /// Service which contains this characteristic
    public let service: Service

    /// Current value of characteristic. If value is not present - it's `nil`.
    public var value: Data? {
        return characteristic.value
    }

    /// The Bluetooth UUID of the `Characteristic` instance.
    public var uuid: CBUUID {
        return characteristic.uuid
    }

    /// Flag which is set to true if characteristic is currently notifying
    public var isNotifying: Bool {
        return characteristic.isNotifying
    }

    /// Properties of characteristic. For more info about this refer to [CBCharacteristicProperties](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/#//apple_ref/c/tdef/CBCharacteristicProperties)
    public var properties: CBCharacteristicProperties {
        return characteristic.properties
    }

    /// Value of this property is an array of `Descriptor` objects. They provide more detailed information about characteristics value.
    public var descriptors: [Descriptor]? {
        return characteristic.descriptors?.map { Descriptor(descriptor: $0, characteristic: self) }
    }

    init(characteristic: CBCharacteristic, service: Service) {
        self.characteristic = characteristic
        self.service = service
    }

    convenience init(characteristic: CBCharacteristic, peripheral: Peripheral) {
        let service = Service(peripheral: peripheral, service: characteristic.service)
        self.init(characteristic: characteristic, service: service)
    }

    /// Function that triggers descriptors discovery for characteristic.
    /// - returns: `Single` that emits `next` with array of `Descriptor` instances, once they're discovered.
    public func discoverDescriptors() -> Single<[Descriptor]> {
        return service.peripheral.discoverDescriptors(for: self)
    }

    /// Function that allow to observe writes that happened for characteristic.
    /// - Returns: `Observable` that emits `next` with `Characteristic` instance every time when write has happened.
    /// It's **infinite** stream, so `.complete` is never called.
    public func observeWrite() -> Observable<Characteristic> {
        return service.peripheral.observeWrite(for: self)
    }

    /// Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
    /// Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/swift/enum/c:@E@CBCharacteristicWriteType), so be sure to check this out before usage of the method.
    /// - parameter data: `Data` that'll be written to the `Characteristic`
    /// - parameter type: Type of write operation. Possible values: `.withResponse`, `.withoutResponse`
    /// - returns: `Single` whose emission depends on `CBCharacteristicWriteType` passed to the function call.
    /// Behavior is following:
    ///
    /// - `withResponse` -  `Observable` emits `next` with `Characteristic` instance write was confirmed without any errors.
    /// If any problem has happened, errors are emitted.
    /// - `withoutResponse` - `Observable` emits `next` with `Characteristic` instance once write was called.
    /// Result of this call is not checked, so as a user you are not sure
    /// if everything completed successfully. Errors are not emitted
    public func writeValue(_ data: Data, type: CBCharacteristicWriteType) -> Single<Characteristic> {
        return service.peripheral.writeValue(data, for: self, type: type)
    }

    /// Function that allow to observe value updates for `Characteristic` instance.
    /// - Returns: `Observable` that emits `Next` with `Characteristic` instance every time when value has changed.
    /// It's **infinite** stream, so `.complete` is never called.
    public func observeValueUpdate() -> Observable<Characteristic> {
        return service.peripheral.observeValueUpdate(for: self)
    }

    /// Function that triggers read of current value of the `Characteristic` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Returns: `Single` which emits `next` with given characteristic when value is ready to read.
    public func readValue() -> Single<Characteristic> {
        return service.peripheral.readValue(for: self)
    }

    /// Setup characteristic notification in order to receive callbacks when given characteristic has been changed.
    /// Returned observable will emit `Characteristic` on every notification change.
    /// It is possible to setup more observables for the same characteristic and the lifecycle of the notification will be shared among them.
    ///
    /// Notification is automaticaly unregistered once this observable is unsubscribed
    ///
    /// - returns: `Observable` emitting `next` with `Characteristic` when given characteristic has been changed.
    ///
    /// This is **infinite** stream of values.
    public func observeValueUpdateAndSetNotification() -> Observable<Characteristic> {
        return service.peripheral.observeValueUpdateAndSetNotification(for: self)
    }
}

extension Characteristic: Equatable {}
extension Characteristic: UUIDIdentifiable {}

/// Compare two characteristics. Characteristics are the same when their UUIDs are the same.
///
/// - parameter lhs: First characteristic to compare
/// - parameter rhs: Second characteristic to compare
/// - returns: True if both characteristics are the same.
public func == (lhs: Characteristic, rhs: Characteristic) -> Bool {
    return lhs.characteristic == rhs.characteristic
}
