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
 Class which describes characteristic's descriptor
 */
public class Descriptor {

    let descriptor: RxDescriptorType

    /// Characteristic to which this descriptor belongs
    public let characteristic: Characteristic

    /// Descriptor UUID
    public var UUID: CBUUID {
        return descriptor.UUID
    }

    /// Descriptor value
    public var value: AnyObject? {
        return descriptor.value
    }

    init(descriptor: RxDescriptorType, characteristic: Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }
}
extension Descriptor: Equatable { }

/**
 Compare two descriptors. Descriptors are the same when their UUIDs are the same.

 - parameter lhs: First descriptor to compare
 - parameter rhs: Second descriptor to compare
 - returns: True if both descriptor are the same.
 */
public func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}
