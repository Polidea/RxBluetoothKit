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

/**
 Class which represents peripheral's service
 */
public class Service {
    let service: RxServiceType

    /// Peripheral to which this service belongs
    public let peripheral: Peripheral

    /// True if service is primary service
    public var isPrimary: Bool {
        return service.isPrimary
    }

    /// Service's UUID
    public var uuid: CBUUID {
        return service.uuid
    }

    /// Service's included services
    public var includedServices: [Service]? {
        return service.includedServices?.map {
            Service(peripheral: peripheral, service: $0)
        } ?? nil
    }

    /// Service's characteristics
    public var characteristics: [Characteristic]? {
        return service.characteristics?.map {
            Characteristic(characteristic: $0, service: self)
        } ?? nil
    }

    /**
     Create new service.
     - parameter peripheral: Peripheral to which this service belongs.
     - parameter service: Service implementation.
     */
    init(peripheral: Peripheral, service: RxServiceType) {
        self.service = service
        self.peripheral = peripheral
    }

    /**
     Wrapper function which allows to discover characteristics form a service class.

     - parameter identifiers: Indentifiers of characteristics which should be discovered. Should be `nil` if
                              user wants to discover all characteristics for this service.
     - returns: Observable which emits array of discovered characteristics after subscription.
     */
    public func discoverCharacteristics(identifiers: [CBUUID]?) -> Observable<[Characteristic]> {
        return peripheral.discoverCharacteristics(identifiers, service: self)
    }
}

extension Service: Equatable {
}

/**
 Compare if services are equal. They are if theirs uuids are the same.

 - parameter lhs: First service
 - parameter rhs: Second service
 - returns: True if services are the same.
 */
public func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.service == rhs.service
}
