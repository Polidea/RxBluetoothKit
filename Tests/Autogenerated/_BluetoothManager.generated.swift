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
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

// swiftlint:disable line_length

/// _BluetoothManager is a class implementing ReactiveX API which wraps all Core Bluetooth Manager's functions allowing to
/// discover, connect to remote peripheral devices and more.
/// You can start using this class by discovering available services of nearby peripherals. Before calling any
/// public `_BluetoothManager`'s functions you should make sure that Bluetooth is turned on and powered on. It can be done
/// by calling and observing returned value of `monitorState()` and then chaining it with `scanForPeripherals(_:options:)`:
/// ```
/// bluetoothManager.rx_state
///     .filter { $0 == .PoweredOn }
///     .take(1)
///     .flatMap { manager.scanForPeripherals(nil) }
/// ```
/// As a result you will receive `_ScannedPeripheral` which contains `_Peripheral` object, `AdvertisementData` and
/// peripheral's RSSI registered during discovery. You can then `connectToPeripheral(_:options:)` and do other operations.
/// - seealso: `_Peripheral`
class _BluetoothManager {

    /// Implementation of Central Manager
    let centralManager: CBCentralManagerMock

    let peripheralDelegateProvider: PeripheralDelegateWrapperProviderMock

    private let delegateWrapper: CBCentralManagerDelegateWrapperMock

    /// Queue on which all observables are serialised if needed
    private let subscriptionQueue: SerializedSubscriptionQueue

    /// Lock which should be used before accessing any internal structures
    private let lock = NSLock()

    /// Queue of scan operations which are waiting for an execution
    private var scanQueue: [_ScanOperation] = []

    // MARK: Initialization

    /// Creates new `_BluetoothManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter queueScheduler: Scheduler on which all serialised operations are executed (such as scans). By default main thread is used.
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    init(
      centralManager: CBCentralManagerMock,
      queueScheduler: SchedulerType = ConcurrentMainScheduler.instance,
      delegateWrapper: CBCentralManagerDelegateWrapperMock,
      peripheralDelegateProvider: PeripheralDelegateWrapperProviderMock
    ) {
        self.centralManager = centralManager
        self.delegateWrapper = delegateWrapper
        self.peripheralDelegateProvider = peripheralDelegateProvider
        subscriptionQueue = SerializedSubscriptionQueue(scheduler: queueScheduler)
        centralManager.delegate = delegateWrapper
    }

    /// Creates new `_BluetoothManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil) {
        let delegateWrapper = CBCentralManagerDelegateWrapperMock()
        self.init(
            centralManager: CBCentralManagerMock(delegate: delegateWrapper, queue: queue, options: options),
            queueScheduler: ConcurrentDispatchQueueScheduler(queue: queue),
            delegateWrapper: delegateWrapper,
            peripheralDelegateProvider: PeripheralDelegateWrapperProviderMock()
        )
    }

    // MARK: Scanning

    /// Scans for `_Peripheral`s after subscription to returned observable. First parameter `serviceUUIDs` is
    /// an array of `_Service` UUIDs which needs to be implemented by a peripheral to be discovered. If user don't want to
    /// filter any peripherals, `nil` can be used instead. Additionally dictionary of
    /// [CBCentralManagerMock specific options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options)
    /// can be passed to allow further customisation.
    /// Scans by default are infinite streams of `_ScannedPeripheral` structures which need to be stopped by the user. For
    /// example this can be done by limiting scanning to certain number of peripherals or time:
    /// ```
    /// bluetoothManager.scanForPeripherals(withServices: nil)
    ///     .timeout(3.0, timeoutScheduler)
    ///     .take(2)
    /// ```
    ///
    /// If different scan is currently in progress and peripherals needed by a user can be discovered by it, new scan is
    /// shared. Otherwise scan is queued on thread specified in `init(centralManager:queueScheduler:)` and will be executed
    /// when other scans finished with complete/error event or were unsubscribed.
    /// As a result you will receive `_ScannedPeripheral` which contains `_Peripheral` object, `AdvertisementData` and
    /// peripheral's RSSI registered during discovery. You can then `connectToPeripheral(_:options:)` and do other
    /// operations.
    /// - seealso: `_Peripheral`
    ///
    /// - parameter serviceUUIDs: Services of peripherals to search for. Nil value will accept all peripherals.
    /// - parameter options: Optional scanning options.
    /// - returns: Infinite stream of scanned peripherals.
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil)
        -> Observable<_ScannedPeripheral> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            let observable: Observable<_ScannedPeripheral> = { [weak self] () -> Observable<_ScannedPeripheral> in
                guard let strongSelf = self else { return .error(_BluetoothError.destroyed) }
                // If it's possible use existing scan - take if from the queue
                strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                if let elem = strongSelf.scanQueue.first(where: { $0.shouldAccept(serviceUUIDs) }) {
                    guard let serviceUUIDs = serviceUUIDs else {
                        return elem.observable
                    }

                    // When binding to existing scan we need to make sure that services are
                    // filtered properly
                    return elem.observable.filter { scannedPeripheral in
                        if let services = scannedPeripheral.advertisementData.serviceUUIDs {
                            return Set(services).isSuperset(of: Set(serviceUUIDs))
                        }
                        return false
                    }
                }

                let scanOperationBox = WeakBox<_ScanOperation>()

                // Create new scan which will be processed in a queue
                let operation = Observable.create { [weak self] (element: AnyObserver<_ScannedPeripheral>) -> Disposable in
                    guard let strongSelf = self else { return Disposables.create() }
                    // Observable which will emit next element, when peripheral is discovered.
                    let disposable = strongSelf.delegateWrapper.didDiscoverPeripheral
                        .flatMap { [weak self] (cbPeripheral, advertisment, rssi) -> Observable<_ScannedPeripheral> in
                            guard let strongSelf = self else { throw _BluetoothError.destroyed }
                            let peripheral = _Peripheral(manager: strongSelf, peripheral: cbPeripheral)
                            let advertismentData = AdvertisementData(advertisementData: advertisment)
                            return .just(_ScannedPeripheral(peripheral: peripheral,
                                                           advertisementData: advertismentData, rssi: rssi))
                        }
                        .subscribe(element)

                    // Start scanning for devices
                    strongSelf.centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)

                    return Disposables.create { [weak self] in
                        guard let strongSelf = self else { return }
                        // When disposed, stop all scans, and remove scanning operation from queue
                        strongSelf.centralManager.stopScan()
                        disposable.dispose()
                        do { strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                            if let index = strongSelf.scanQueue.index(where: { $0 == scanOperationBox.value! }) {
                                strongSelf.scanQueue.remove(at: index)
                            }
                        }
                    }
                }
                .queueSubscribe(on: strongSelf.subscriptionQueue)
                .publish()
                .refCount()

                let scanOperation = _ScanOperation(uuids: serviceUUIDs, observable: operation)
                strongSelf.scanQueue.append(scanOperation)

                scanOperationBox.value = scanOperation
                return operation
            }()
            // Allow scanning as long as bluetooth is powered on
            return strongSelf.ensure(.poweredOn, observable: observable)
        }
    }

    // MARK: State

    /// Continuous state of `_BluetoothManager` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Observable that emits `Next` immediately after subscribtion with current state of Bluetooth. Later,
    /// whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
    var rx_state: Observable<BluetoothState> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            return strongSelf.delegateWrapper.didUpdateState.startWith(strongSelf.state)
        }
    }

    /// Current state of `_BluetoothManager` instance described by `BluetoothState` which is equivalent to [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Current state of `_BluetoothManager` as `BluetoothState`.
    var state: BluetoothState {
        return BluetoothState(rawValue: centralManager.state.rawValue) ?? .unsupported
    }

    // MARK: _Peripheral's Connection Management

    /// Establishes connection with `_Peripheral` after subscription to returned observable. It's user responsibility
    /// to close connection with `cancelConnectionToPeripheral(_:)` after subscription was completed. Unsubscribing from
    /// returned observable cancels connection attempt. By default observable is waiting infinitely for successful connection.
    /// Additionally you can pass optional [dictionary](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Connection_Options)
    /// to customise the behaviour of connection.
    /// - parameter peripheral: The `_Peripheral` to which `_BluetoothManager` is attempting to connect.
    /// - parameter options: Dictionary to customise the behaviour of connection.
    /// - returns: `Single` which emits next event after connection is established.
    func connect(_ peripheral: _Peripheral, options: [String: Any]? = nil)
        -> Single<_Peripheral> {

        let success = delegateWrapper.didConnectPeripheral
            .filter { $0 == peripheral.peripheral }
            .take(1)
            .map { _ in return peripheral }

        let error = delegateWrapper.didFailToConnectPeripheral
            .filter { $0.0 == peripheral.peripheral }
            .take(1)
            .map { [weak self] (cbPeripheral, error) -> _Peripheral in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                throw _BluetoothError.peripheralConnectionFailed(_Peripheral(manager: strongSelf, peripheral: cbPeripheral), error)
            }

        let observable = Observable<_Peripheral>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(_BluetoothError.destroyed)
                return Disposables.create()
            }
            if let error = _BluetoothError(state: strongSelf.state) {
                observer.onError(error)
                return Disposables.create()
            }

            guard !peripheral.isConnected else {
                observer.onNext(peripheral)
                observer.onCompleted()
                return Disposables.create()
            }

            let disposable = success.amb(error).subscribe(observer)

            strongSelf.centralManager.connect(peripheral.peripheral, options: options)

            return Disposables.create { [weak self] in
                guard let strongSelf = self else { return }
                if !peripheral.isConnected {
                    strongSelf.centralManager.cancelPeripheralConnection(peripheral.peripheral)
                    disposable.dispose()
                }
            }
        }

        return ensure(.poweredOn, observable: observable).asSingle()
    }

    /// Cancels an active or pending local connection to a `_Peripheral` after observable subscription. It is not guaranteed
    /// that physical connection will be closed immediately as well and all pending commands will not be executed.
    ///
    /// - parameter peripheral: The `_Peripheral` to which the `_BluetoothManager` is either trying to
    /// connect or has already connected.
    /// - returns: `Single` which emits next event when peripheral successfully cancelled connection.
    func cancelPeripheralConnection(_ peripheral: _Peripheral) -> Single<(_Peripheral)> {
        let observable = Observable<(_Peripheral, DisconnectionReason?)>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(_BluetoothError.destroyed)
                return Disposables.create()
            }
            let disposable = strongSelf.monitorDisconnection(for: peripheral).take(1).subscribe(observer)
            strongSelf.centralManager.cancelPeripheralConnection(peripheral.peripheral)
            return disposable
        }
      return ensure(.poweredOn, observable: observable)
          .asSingle()
          .map { $0.0 }
    }

    // MARK: Retrieving Lists of Peripherals

    /// Returns observable list of the `_Peripheral`s which are currently connected to the `_BluetoothManager` and contain
    /// all of the specified `_Service`'s UUIDs.
    ///
    /// - parameter serviceUUIDs: A list of `_Service` UUIDs
    /// - returns: `Single` which emits retrieved `_Peripheral`s. They are in connected state and contain all of the
    /// `_Service`s with UUIDs specified in the `serviceUUIDs` parameter.
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Single<[_Peripheral]> {
        let observable = Observable<[_Peripheral]>.deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            return Observable.just(strongSelf.centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs))
                .map { [weak self] (peripheralTable: [CBPeripheralMock]) -> [_Peripheral] in
                    guard let strongSelf = self else { throw _BluetoothError.destroyed }
                    return peripheralTable.map {
                        _Peripheral(manager: strongSelf, peripheral: $0)
                    }
                }
        }
        return ensure(.poweredOn, observable: observable).asSingle()
    }

    /// Returns observable list of `_Peripheral`s by their identifiers which are known to `_BluetoothManager`.
    ///
    /// - parameter identifiers: List of `_Peripheral`'s identifiers which should be retrieved.
    /// - returns: `Single` which emits next event when list of `_Peripheral`s are retrieved.
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Single<[_Peripheral]> {
        let observable = Observable<[_Peripheral]>.deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            return Observable.just(strongSelf.centralManager.retrievePeripherals(withIdentifiers: identifiers))
                .map { [weak self] (peripheralTable: [CBPeripheralMock]) -> [_Peripheral] in
                    guard let strongSelf = self else { throw _BluetoothError.destroyed }
                    return peripheralTable.map {
                        _Peripheral(manager: strongSelf, peripheral: $0)
                    }
                }
        }
        return ensure(.poweredOn, observable: observable).asSingle()
    }

    // MARK: Internal functions

    /// Ensure that `state` is and will be the only state of `_BluetoothManager` during subscription.
    /// Otherwise error is emitted.
    /// - parameter state: `BluetoothState` which should be present during subscription.
    /// - parameter observable: Observable into which potential errors should be merged.
    /// - returns: New observable which merges errors with source observable.
    func ensure<T>(_ state: BluetoothState, observable: Observable<T>) -> Observable<T> {
        let statesObservable = rx_state
            .filter { $0 != state && _BluetoothError(state: $0) != nil }
            .map { state -> T in throw _BluetoothError(state: state)! }
        return .absorb(statesObservable, observable)
    }

    /// Ensure that specified `peripheral` is connected during subscription.
    /// - parameter peripheral: `_Peripheral` which should be connected during subscription.
    /// - returns: Observable which emits error when `peripheral` is disconnected during subscription.
    func ensurePeripheralIsConnected<T>(_ peripheral: _Peripheral) -> Observable<T> {
        return .deferred {
            if !peripheral.isConnected {
                throw _BluetoothError.peripheralDisconnected(peripheral, nil)
            }
            return self.delegateWrapper.didDisconnectPeripheral
                .filter { $0.0 == peripheral.peripheral }
                .map { (_, error) -> T in
                    throw _BluetoothError.peripheralDisconnected(peripheral, error)
                }
        }
    }

    /// Emits `_Peripheral` instance when it's connected.
    /// - Parameter peripheral: `_Peripheral` which is monitored for connection.
    /// - Returns: Observable which emits next events when `peripheral` was connected.
    func monitorConnection(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        let observable = delegateWrapper.didConnectPeripheral
          .filter { $0 == peripheral.peripheral }
          .map { _ in peripheral }
      return ensure(.poweredOn, observable: observable)
    }

    typealias DisconnectionReason = Error
    /// Emits `_Peripheral` instance when it's disconnected.
    /// - Parameter peripheral: `_Peripheral` which is monitored for disconnection.
    /// - Returns: Observable which emits next events when `_Peripheral` instance was disconnected.
    /// It provides optional error which may contain more information about the cause of the disconnection
    /// if it wasn't the `cancelConnection` call
    func monitorDisconnection(for peripheral: _Peripheral) -> Observable<(_Peripheral, DisconnectionReason?)> {
        let observable = delegateWrapper.didDisconnectPeripheral
          .filter { $0.0 == peripheral.peripheral }
          .map { (_, error) -> (_Peripheral, DisconnectionReason?) in (peripheral, error) }
        return ensure(.poweredOn, observable: observable)
    }

    #if os(iOS)
        /// Emits `_RestoredState` instance, when state of `_BluetoothManager` has been restored,
        /// Should only be called once in the lifetime of the app
        /// - Returns: Observable which emits next events state has been restored
        func listenOnRestoredState() -> Observable<_RestoredState> {
            return delegateWrapper
                .willRestoreState
                .take(1)
                .flatMap { [weak self] dict -> Observable<_RestoredState> in
                    guard let strongSelf = self else { throw _BluetoothError.destroyed }
                    return .just(_RestoredState(restoredStateDictionary: dict, bluetoothManager: strongSelf))
                }
        }
    #endif
}
