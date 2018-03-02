import Foundation
import CoreBluetooth
@testable import RxBluetoothKit

/// Class for providing peripherals and peripheral wrappers
class _PeripheralProvider {

    private let peripheralsBox: ThreadSafeBox<[_Peripheral]> = ThreadSafeBox(value: [])

    private let delegateWrappersBox: ThreadSafeBox<[UUID: CBPeripheralDelegateWrapperMock]> = ThreadSafeBox(value: [:])

    /// Provides `CBPeripheralDelegateWrapperMock` for specified `CBPeripheralMock`.
    ///
    /// If it was previously created it returns that object, so that there can be only
    /// one `CBPeripheralDelegateWrapperMock` per `CBPeripheralMock`.
    ///
    /// If not it creates new one.
    ///
    /// - parameter peripheral: _Peripheral for which to provide delegate wrapper
    /// - returns: Delegate wrapper for specified peripheral.
    func provideDelegateWrapper(for peripheral: CBPeripheralMock) -> CBPeripheralDelegateWrapperMock {
        if let delegateWrapper = delegateWrappersBox.read({ $0[peripheral.uuidIdentifier] }) {
            return delegateWrapper
        } else {
            delegateWrappersBox.compareAndSet(
                compare: { $0[peripheral.uuidIdentifier] == nil },
                set: { $0[peripheral.uuidIdentifier] = CBPeripheralDelegateWrapperMock()}
            )
            return delegateWrappersBox.read({ $0[peripheral.uuidIdentifier]! })
        }
    }

    /// Provides `_Peripheral` for specified `CBPeripheralMock`.
    ///
    /// If it was previously created it returns that object, so that there can be only one `_Peripheral`
    /// per `CBPeripheralMock`. If not it creates new one.
    ///
    /// - parameter peripheral: _Peripheral for which to provide delegate wrapper
    /// - returns: `_Peripheral` for specified peripheral.
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
