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
@testable import RxBluetoothKit

/// Class for providing peripherals and peripheral wrappers
class _PeripheralProvider {

    private let peripheralsBox: ThreadSafeBox<[_Peripheral]> = ThreadSafeBox(value: [])

    private let delegateWrappersBox: ThreadSafeBox<[UUID: CBPeripheralDelegateWrapperMock]> = ThreadSafeBox(value: [:])

    /**
     Provides `CBPeripheralDelegateWrapperMock` for specified `CBPeripheralMock`.
     
     If it was previously created it returns that object, so that there can be only
     one `CBPeripheralDelegateWrapperMock` per `CBPeripheralMock`.
     
     If not it creates new one.
     
     - parameter peripheral: _Peripheral for which to provide delegate wrapper
     - returns: Delegate wrapper for specified peripheral.
     */
    func provideDelegateWrapper(for peripheral: CBPeripheralMock) -> CBPeripheralDelegateWrapperMock {
        if let delegateWrapper = delegateWrappersBox.read({ $0[peripheral.identifier] }) {
            return delegateWrapper
        } else {
            delegateWrappersBox.compareAndSet(
                compare: { $0[peripheral.identifier] == nil },
                set: { $0[peripheral.identifier] = CBPeripheralDelegateWrapperMock()}
            )
            return delegateWrappersBox.read({ $0[peripheral.identifier]! })
        }
    }

    /**
     Provides `_Peripheral` for specified `CBPeripheralMock`.
     
     If it was previously created it returns that object, so that there can be only one `_Peripheral` per `CBPeripheralMock`.
     
     If not it creates new one.
     
     - parameter peripheral: _Peripheral for which to provide delegate wrapper
     - returns: `_Peripheral` for specified peripheral.
     */
    func provide(for cbPeripheral: CBPeripheralMock, centralManager: _CentralManager) -> _Peripheral {
        if let peripheral = find(cbPeripheral) {
            return peripheral
        } else {
            return createAndAddToBox(cbPeripheral, manager: centralManager)
        }
    }

    fileprivate func createAndAddToBox(_ cbPeripheral: CBPeripheralMock, manager: _CentralManager) -> _Peripheral {
        peripheralsBox.compareAndSet(
            compare: { peripherals in
                return !peripherals.contains(where: { $0.peripheral == cbPeripheral })
        },
            set: { [weak self] peripherals in
                guard let strongSelf = self else { return }
                let delegateWrapper = strongSelf.provideDelegateWrapper(for: cbPeripheral)
                let newPeripheral = _Peripheral(
                    manager: manager,
                    peripheral: cbPeripheral,
                    delegateWrapper: delegateWrapper
                )
                peripherals.append(newPeripheral)
            }
        )
        return peripheralsBox.read { peripherals in
            return peripherals.first(where: { $0.peripheral == cbPeripheral })!
        }
    }

    fileprivate func find(_ cbPeripheral: CBPeripheralMock) -> _Peripheral? {
        return peripheralsBox.read { peripherals in
            return peripherals.first(where: { $0.peripheral == cbPeripheral})
        }
    }
}
