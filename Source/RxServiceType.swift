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

/**
 Protocol which wraps bluetooth service.
 */
protocol RxServiceType {

    /// Service's UUID
    var uuid: CBUUID { get }

    /// Service's characteristics
    var characteristics: [RxCharacteristicType]? { get }

    /// Service's included services
    var includedServices: [RxServiceType]? { get }

    /// True if service is a primary service
    var isPrimary: Bool { get }
}

extension Equatable where Self: RxServiceType {}

/**
 Services are equal if their UUIDs are equal

 - parameter lhs: First service to compare
 - parameter rhs: Second service to compare
 - returns: True if services UUIDs are the same.
 */
func == (lhs: RxServiceType, rhs: RxServiceType) -> Bool {
    return lhs.uuid == rhs.uuid
}

/**
 Function compares if two services arrays are the same, which is true if
 both of them in sequence are equal and their size is the same.

 - parameter lhs: First array of services to compare
 - parameter rhs: Second array of services to compare
 - returns: True if both arrays contain same services
 */
func == (lhs: [RxServiceType], rhs: [RxServiceType]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }

    return lhs.starts(with: rhs, by: ==)
}
