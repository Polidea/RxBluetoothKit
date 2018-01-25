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

/// _Descriptor is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with
/// [CBDescriptorMock](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBDescriptor_Class/)
/// Descriptors provide more information about a characteristic’s value.
class _Descriptor {

    let descriptor: CBDescriptorMock

    /// _Characteristic to which this descriptor belongs.
    let characteristic: _Characteristic

    /// The Bluetooth UUID of the `_Descriptor` instance.
    var uuid: CBUUID {
        return descriptor.uuid
    }

    /// The value of the descriptor. It can be written and read through functions on `_Descriptor` instance.
    var value: Any? {
        return descriptor.value
    }

    init(descriptor: CBDescriptorMock, characteristic: _Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }

    convenience init(descriptor: CBDescriptorMock, peripheral: _Peripheral) {
        let service = _Service(peripheral: peripheral, service: descriptor.characteristic.service)
        let characteristic = _Characteristic(characteristic: descriptor.characteristic, service: service)
        self.init(descriptor: descriptor, characteristic: characteristic)
    }

    /// Function that allow to observe writes that happened for descriptor.
    /// - Returns: Observable that emits `Next` with `_Descriptor` instance every time when write has happened.
    /// It's **infinite** stream, so `.Complete` is never called.
    func observeWrite() -> Observable<_Descriptor> {
        return characteristic.service.peripheral.observeWrite(for: self)
    }

    /// Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
    /// - Parameter data: `NSData` that'll be written to `_Descriptor` instance
    /// - Returns: `Single` that emits `Next` with `_Descriptor` instance, once value is written successfully.
    func writeValue(_ data: Data) -> Single<_Descriptor> {
        return characteristic.service.peripheral.writeValue(data, for: self)
    }

    /// Function that allow to observe value updates for `_Descriptor` instance.
    /// - Returns: Observable that emits `Next` with `_Descriptor` instance every time when value has changed.
    /// It's **infinite** stream, so `.Complete` is never called.
    func observeValueUpdate() -> Observable<_Descriptor> {
        return characteristic.service.peripheral.observeValueUpdate(for: self)
    }

    /// Function that triggers read of current value of the `_Descriptor` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Returns: `Single` which emits `Next` with given descriptor when value is ready to read.
    func readValue() -> Single<_Descriptor> {
        return characteristic.service.peripheral.readValue(for: self)
    }
}

extension _Descriptor: Equatable {}

/// Compare two descriptors. Descriptors are the same when their UUIDs are the same.
///
/// - parameter lhs: First descriptor to compare
/// - parameter rhs: Second descriptor to compare
/// - returns: True if both descriptor are the same.
func == (lhs: _Descriptor, rhs: _Descriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}
