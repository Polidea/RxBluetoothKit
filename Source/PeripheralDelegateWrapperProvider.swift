// The MIT License (MIT)
//
// Copyright (c) 2018 Polidea
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

/// Class for providing delegate wrappers
class PeripheralDelegateWrapperProvider {

    /// Lock which should be used before accessing any internal structures
    private let lock = NSLock()

    /// Peripheral identifier to CBPeripheralDelegateWrapper map
    private var peripheralDelegateWrappersMap: [UUID: CBPeripheralDelegateWrapper] = [:]

    /// Provides delegate wrapper for specified CBPeripheral.
    /// If wrapper was already created for specified Peripheral it returns that wrapper.
    /// If not it creates new wrapper.
    ///
    /// - parameter peripheral: Peripheral for which to provide delegate wrapper
    /// - returns: Delegate wrapper for specified peripheral.
    func provide(for peripheral: CBPeripheral) -> CBPeripheralDelegateWrapper {
        lock.lock(); defer { lock.unlock() }
        if let wrapper = peripheralDelegateWrappersMap[peripheral.uuidIdentifier] {
            return wrapper
        }
        let wrapper = CBPeripheralDelegateWrapper()
        peripheralDelegateWrappersMap[peripheral.uuidIdentifier] = wrapper
        return wrapper
    }
}
