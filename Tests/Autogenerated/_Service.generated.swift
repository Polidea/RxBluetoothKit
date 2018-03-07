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

// swiftlint:disable line_length
/// _Service is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with [CBServiceMock](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBService_Class/)
class _Service {
    /// Intance of CoreBluetooth service class
    let service: CBServiceMock

    /// _Peripheral to which this service belongs
    let peripheral: _Peripheral

    /// True if service is primary service
    var isPrimary: Bool {
        return service.isPrimary
    }

    /// _Service's UUID
    var uuid: CBUUID {
        return service.uuid
    }

    /// _Service's included services
    var includedServices: [_Service]? {
        return service.includedServices?.map {
            _Service(peripheral: peripheral, service: $0)
        }
    }

    /// _Service's characteristics
    var characteristics: [_Characteristic]? {
        return service.characteristics?.map {
            _Characteristic(characteristic: $0, service: self)
        }
    }

    init(peripheral: _Peripheral, service: CBServiceMock) {
        self.service = service
        self.peripheral = peripheral
    }

    /// Function that triggers characteristics discovery for specified Services and identifiers. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// - Parameter identifiers: Identifiers of characteristics that should be discovered. If `nil` - all of the
    /// characteristics will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Returns: `Single` that emits `next` with array of `_Characteristic` instances, once they're discovered.
    /// If not all requested characteristics are discovered, `RxError.noElements` error is emmited.
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?) -> Single<[_Characteristic]> {
        return peripheral.discoverCharacteristics(characteristicUUIDs, for: self)
    }

    /// Function that triggers included services discovery for specified services. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// - Parameter includedServiceUUIDs: Identifiers of included services that should be discovered. If `nil` - all of the
    /// included services will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Returns: `Single` that emits `next` with array of `_Service` instances, once they're discovered.
    // If not all requested services are discovered, `RxError.noElements` error is emmited.
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?) -> Single<[_Service]> {
        return peripheral.discoverIncludedServices(includedServiceUUIDs, for: self)
    }
}

extension _Service: Equatable {}
extension _Service: UUIDIdentifiable {}

/// Compare if services are equal. They are if theirs uuids are the same.
/// - parameter lhs: First service
/// - parameter rhs: Second service
/// - returns: True if services are the same.
func == (lhs: _Service, rhs: _Service) -> Bool {
    return lhs.service == rhs.service
}
