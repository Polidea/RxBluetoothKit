import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

/// `ConnectorMock` is a class that is responsible for establishing connection with peripherals.
class _Connector {
    let centralManager: CBCentralManagerMock
    let delegateWrapper: CBCentralManagerDelegateWrapperMock
    let connectedBox: ThreadSafeBox<Set<UUID>> = ThreadSafeBox(value: [])
    let disconnectingBox: ThreadSafeBox<Set<UUID>> = ThreadSafeBox(value: [])

    init(
        centralManager: CBCentralManagerMock,
        delegateWrapper: CBCentralManagerDelegateWrapperMock
    ) {
        self.centralManager = centralManager
        self.delegateWrapper = delegateWrapper
    }

    /// Establishes connection with a given `_Peripheral`.
    /// For more information see `_CentralManager.establishConnection(with:options:)`
    func establishConnection(with peripheral: _Peripheral, options: [String: Any]? = nil)
        -> Observable<_Peripheral> {
            return .deferred { [weak self] in
                guard let self = self else {
                    return Observable.error(_BluetoothError.destroyed)
                }

                let connectionObservable = self.createConnectionObservable(for: peripheral, options: options)

                let waitForDisconnectObservable = self.delegateWrapper.didDisconnectPeripheral
                    .filter { $0.0 == peripheral.peripheral }
                    .take(1)
                    .do(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.disconnectingBox.write { $0.remove(peripheral.identifier) }
                    })
                    .map { _ in peripheral }
                let isDisconnectingObservable: Observable<_Peripheral> = Observable.create { observer in
                    var isDiconnecting = self.disconnectingBox.read { $0.contains(peripheral.identifier) }
                    let isDisconnected = peripheral.state == .disconnected
                    // it means that peripheral is already disconnected, but we didn't update disconnecting box
                    if isDiconnecting && isDisconnected {
                        self.disconnectingBox.write { $0.remove(peripheral.identifier) }
                        isDiconnecting = false
                    }
                    if !isDiconnecting {
                        observer.onNext(peripheral)
                    }
                    return Disposables.create()
                }
                return waitForDisconnectObservable.amb(isDisconnectingObservable)
                    .flatMap { _ in connectionObservable }
            }
    }

    fileprivate func createConnectionObservable(
        for peripheral: _Peripheral,
        options: [String: Any]? = nil
    ) -> Observable<_Peripheral> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(_BluetoothError.destroyed)
                return Disposables.create()
            }

            let connectingStarted = self.connectedBox.compareAndSet(
                compare: { !$0.contains(peripheral.identifier) },
                set: { $0.insert(peripheral.identifier) }
            )

            guard connectingStarted else {
                observer.onError(_BluetoothError.peripheralIsAlreadyObservingConnection(peripheral))
                return Disposables.create()
            }

            let connectedObservable = self.createConnectedObservable(for: peripheral)
            let failToConnectObservable = self.createFailToConnectObservable(for: peripheral)
            let disconnectedObservable = self.createDisconnectedObservable(for: peripheral)

            let disposable: Disposable
            if peripheral.isConnected {
                disposable = disconnectedObservable.subscribe(onError: { observer.onError($0) })
                observer.onNext(peripheral)
            } else {
                disposable = connectedObservable.amb(failToConnectObservable)
                    .do(onNext: { observer.onNext($0) })
                    .flatMap { _ in disconnectedObservable }
                    .subscribe(onError: { observer.onError($0) })

                self.centralManager.connect(peripheral.peripheral, options: options)
            }

            return Disposables.create { [weak self] in
                guard let self = self else { return }
                disposable.dispose()
                let isConnected = self.connectedBox.read { $0.contains(peripheral.identifier) }
                if isConnected {
                    self.disconnectingBox.write { $0.insert(peripheral.identifier) }
                    self.centralManager.cancelPeripheralConnection(peripheral.peripheral)
                    self.connectedBox.write { $0.remove(peripheral.identifier) }
                }
            }
        }
    }

    fileprivate func createConnectedObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        return delegateWrapper.didConnectPeripheral
            .filter { $0 == peripheral.peripheral }
            .take(1)
            .map { _ in peripheral }
    }

    fileprivate func createDisconnectedObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        return delegateWrapper.didDisconnectPeripheral
            .filter { $0.0 == peripheral.peripheral }
            .take(1)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.connectedBox.write { $0.remove(peripheral.identifier) }
                self.disconnectingBox.write { $0.remove(peripheral.identifier) }
            })
            .map { (_, error) -> _Peripheral in
                throw _BluetoothError.peripheralDisconnected(peripheral, error)
            }
    }

    fileprivate func createFailToConnectObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        return delegateWrapper.didFailToConnectPeripheral
            .filter { $0.0 == peripheral.peripheral }
            .take(1)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.connectedBox.write { $0.remove(peripheral.identifier) }
            })
            .map { (_, error) -> _Peripheral in
                throw _BluetoothError.peripheralConnectionFailed(peripheral, error)
            }
    }
}
