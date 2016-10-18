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
 Protocol which wraps characteristic for bluetooth devices.
 */
protocol RxCharacteristicType {

    /// Characteristic UUID
    var uuid: CBUUID { get }

    /// Current characteristic value
    var value: Data? { get }

    /// True if characteristic value changes are notified
    var isNotifying: Bool { get }

    /// Characteristic properties
    var properties: CBCharacteristicProperties { get }

    /// Characteristic descriptors
    var descriptors: [RxDescriptorType]? { get }

    /// Characteristic service
    var service: RxServiceType { get }
}

/**
 Characteristics are equal if their UUIDs are equal

 - parameter lhs: First characteristic to compare
 - parameter rhs: Second characteristic to compare
 - returns: True if characteristics are the same
 */
func == (lhs: RxCharacteristicType, rhs: RxCharacteristicType) -> Bool {
    return lhs.uuid == rhs.uuid
}

/**
 Function compares if two characteristic arrays are the same, which is true if
 both of them in sequence are equal and their size is the same.

 - parameter lhs: First array of characteristics to compare
 - parameter rhs: Second array of characteristics to compare
 - returns: True if both arrays contain same characteristics
 */
func == (lhs: [RxCharacteristicType], rhs: [RxCharacteristicType]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }

    return lhs.starts(with: rhs, by: ==)
}
