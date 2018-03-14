import Foundation
import RxSwift
import CoreBluetooth

/// `Connector` is a class that is responsible for establishing connection with peripherals.
class Connector {
    let centralManager: CBCentralManager
    let delegateWrapper: CBCentralManagerDelegateWrapper
    let connectingBox: ThreadSafeBox<Set<UUID>> = ThreadSafeBox(value: [])
    let disconnectingBox: ThreadSafeBox<Set<UUID>> = ThreadSafeBox(value: [])

    init(
        centralManager: CBCentralManager,
        delegateWrapper: CBCentralManagerDelegateWrapper
    ) {
        self.centralManager = centralManager
        self.delegateWrapper = delegateWrapper
    }

    /// Establishes connection with a given `Peripheral`.
    /// For more information see `CentralManager.establishConnection(with:options:)`
    func establishConnection(with peripheral: Peripheral, options: [String: Any]? = nil)
        -> Observable<Peripheral> {
            return .deferred { [weak self] in
                guard let strongSelf = self else {
                    return Observable.error(BluetoothError.destroyed)
                }

                let connectionObservable = strongSelf.createConnectionObservable(for: peripheral, options: options)

                let waitForDisconnectObservable = strongSelf.delegateWrapper.didDisconnectPeripheral
                    .filter { $0.0 == peripheral.peripheral }
                    .take(1)
                    .do(onNext: { [weak self] _ in
                        guard let strongSelf = self else { return }
                        strongSelf.disconnectingBox.write { $0.remove(peripheral.identifier) }
                    })
                    .map { _ in peripheral }
                let isDisconnectingObservable: Observable<Peripheral> = Observable.create { observer in
                    var isDiconnecting = strongSelf.disconnectingBox.read { $0.contains(peripheral.identifier) }
                    let isDisconnected = peripheral.state == .disconnected
                    // it means that peripheral is already disconnected, but we didn't update disconnecting box
                    if isDiconnecting && isDisconnected {
                        strongSelf.disconnectingBox.write { $0.remove(peripheral.identifier) }
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
        for peripheral: Peripheral,
        options: [String: Any]? = nil
    ) -> Observable<Peripheral> {
        return Observable.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(BluetoothError.destroyed)
                return Disposables.create()
            }

            let connectingStarted = strongSelf.connectingBox.compareAndSet(
                compare: { !peripheral.isConnected && !$0.contains(peripheral.identifier) },
                set: { $0.insert(peripheral.identifier) }
            )

            guard connectingStarted else {
                observer.onError(BluetoothError.peripheralIsConnectingOrAlreadyConnected(peripheral))
                return Disposables.create()
            }

            let connectedObservable = strongSelf.createConnectedObservable(for: peripheral)
            let failToConnectObservable = strongSelf.createFailToConnectObservable(for: peripheral)
            let disconnectedObservable = strongSelf.createDisconnectedObservable(for: peripheral)

            let disposable = connectedObservable.amb(failToConnectObservable)
                .do(onNext: { observer.onNext($0) })
                .flatMap { _ in disconnectedObservable }
                .subscribe(onError: { observer.onError($0) })

            strongSelf.centralManager.connect(peripheral.peripheral, options: options)

            return Disposables.create { [weak self] in
                guard let strongSelf = self else { return }
                disposable.dispose()
                let isConnecting = strongSelf.connectingBox.read { $0.contains(peripheral.identifier) }
                if isConnecting || peripheral.isConnected {
                    strongSelf.disconnectingBox.write { $0.insert(peripheral.identifier) }
                    strongSelf.centralManager.cancelPeripheralConnection(peripheral.peripheral)
                    strongSelf.connectingBox.write { $0.remove(peripheral.identifier) }
                }
            }
        }
    }

    fileprivate func createConnectedObservable(for peripheral: Peripheral) -> Observable<Peripheral> {
        return delegateWrapper.didConnectPeripheral
            .filter { $0 == peripheral.peripheral }
            .take(1)
            .map { _ in peripheral }
            .do(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.connectingBox.write { $0.remove(peripheral.identifier) }
            })
    }

    fileprivate func createDisconnectedObservable(for peripheral: Peripheral) -> Observable<Peripheral> {
        return delegateWrapper.didDisconnectPeripheral
            .filter { $0.0 == peripheral.peripheral }
            .take(1)
            .do(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.disconnectingBox.write { $0.remove(peripheral.identifier) }
            })
            .map { (_, error) -> Peripheral in
                throw BluetoothError.peripheralDisconnected(peripheral, error)
            }
    }

    fileprivate func createFailToConnectObservable(for peripheral: Peripheral) -> Observable<Peripheral> {
        return delegateWrapper.didFailToConnectPeripheral
            .filter { $0.0 == peripheral.peripheral }
            .take(1)
            .do(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.connectingBox.write { $0.remove(peripheral.identifier) }
            })
            .map { (_, error) -> Peripheral in
                throw BluetoothError.peripheralConnectionFailed(peripheral, error)
            }
    }
}
