import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

/// Error received when device disconnection event occurs
typealias DisconnectionReason = Error

/// _CentralManager is a class implementing ReactiveX API which wraps all Core Bluetooth Manager's functions allowing to
/// discover, connect to remote peripheral devices and more.
/// You can start using this class by discovering available services of nearby peripherals. Before calling any
/// public `_CentralManager`'s functions you should make sure that Bluetooth is turned on and powered on.
/// It can be done by calling and observing returned value of `observeStateWithInitialValue()` and then
/// chaining it with `scanForPeripherals(_:options:)`:
/// ```
/// let disposable = centralManager.observeStateWithInitialValue()
///     .filter { $0 == .poweredOn }
///     .take(1)
///     .flatMap { centralManager.scanForPeripherals(nil) }
/// ```
/// As a result you will receive `_ScannedPeripheral` which contains `_Peripheral` object, `AdvertisementData` and
/// peripheral's RSSI registered during discovery. You can then `establishConnection(_:options:)` and do other operations.
/// You can also simply stop scanning with just disposing it:
/// ```
/// disposable.dispose()
/// ```
/// - seealso: `_Peripheral`
class _CentralManager: _ManagerType {

    /// Implementation of CBCentralManagerMock
    let manager: CBCentralManagerMock

    @available(*, deprecated, renamed: "_CentralManager.manager")
    var centralManager: CBCentralManagerMock { return manager }

    let peripheralProvider: PeripheralProviderMock

    let delegateWrapper: CBCentralManagerDelegateWrapperMock

    /// Lock which should be used before accessing any internal structures
    private let lock = NSLock()

    /// Ongoing scan disposable
    private var scanDisposable: Disposable?

    /// ConnectorMock instance is used for establishing connection with peripherals
    private let connector: ConnectorMock

    // MARK: Initialization

    /// Creates new `_CentralManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    /// - parameter peripheralProvider: Provider for providing peripherals and peripheral wrappers
    /// - parameter connector: ConnectorMock instance which is used for establishing connection with peripherals.
    init(
        centralManager: CBCentralManagerMock,
        delegateWrapper: CBCentralManagerDelegateWrapperMock,
        peripheralProvider: PeripheralProviderMock,
        connector: ConnectorMock
    ) {
        self.manager = centralManager
        self.delegateWrapper = delegateWrapper
        self.peripheralProvider = peripheralProvider
        self.connector = connector
        centralManager.delegate = delegateWrapper
    }

    /// Creates new `_CentralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    /// - parameter cbCentralManager: Optional instance of `CBCentralManagerMock` to be used as a `manager`. If you
    /// skip this parameter, there will be created an instance of `CBCentralManagerMock` using given queue and options.
    convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            cbCentralManager: CBCentralManagerMock? = nil) {
        let delegateWrapper = CBCentralManagerDelegateWrapperMock()
        let centralManager = cbCentralManager ??
            CBCentralManagerMock(delegate: delegateWrapper, queue: queue, options: options)
        self.init(
            centralManager: centralManager,
            delegateWrapper: delegateWrapper,
            peripheralProvider: PeripheralProviderMock(),
            connector: ConnectorMock(centralManager: centralManager, delegateWrapper: delegateWrapper)
        )
    }

    /// Attaches RxBluetoothKit delegate to CBCentralManagerMock.
    /// This method is useful in cases when delegate of CBCentralManagerMock was reassigned outside of
    /// RxBluetoothKit library (e.g. CBCentralManagerMock was used in some other library or used in non-reactive way)
    func attach() {
        manager.delegate = delegateWrapper
    }

    // MARK: State

    var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unknown
    }

    func observeState() -> Observable<BluetoothState> {
        return self.delegateWrapper.didUpdateState.asObservable()
    }

    func observeStateWithInitialValue() -> Observable<BluetoothState> {
        return Observable.deferred { [weak self] in
            guard let self = self else {
                RxBluetoothKitLog.w("observeState - _CentralManager deallocated")
                return .never()
            }

            return self.delegateWrapper.didUpdateState.asObservable()
                .startWith(self.state)
        }
    }

    // MARK: Scanning

    /// Value indicating if manager is currently scanning.
    var isScanInProgress: Bool {
        lock.lock(); defer { lock.unlock() }
        return scanDisposable != nil
    }

    /// Scans for `_Peripheral`s after subscription to returned observable. First parameter `serviceUUIDs` is
    /// an array of `_Service` UUIDs which needs to be implemented by a peripheral to be discovered. If user don't want to
    /// filter any peripherals, `nil` can be used instead. Additionally dictionary of
    /// [CBCentralManagerMock specific options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options)
    /// can be passed to allow further customisation.
    /// Scans by default are infinite streams of `_ScannedPeripheral` structures which need to be stopped by the user. For
    /// example this can be done by limiting scanning to certain number of peripherals or time:
    /// ```
    /// centralManager.scanForPeripherals(withServices: nil)
    ///     .timeout(3.0, timeoutScheduler)
    ///     .take(2)
    /// ```
    ///
    /// There can be only one ongoing scanning. It will return `_BluetoothError.scanInProgress` error if
    /// this method will be called when there is already ongoing scan.
    /// As a result you will receive `_ScannedPeripheral` which contains `_Peripheral` object, `AdvertisementData` and
    /// peripheral's RSSI registered during discovery. You can then `establishConnection(_:options:)` and do other
    /// operations.
    ///
    /// - seealso: `_Peripheral`
    ///
    /// - parameter serviceUUIDs: Services of peripherals to search for. Nil value will accept all peripherals.
    /// - parameter options: Optional scanning options.
    /// - returns: Infinite stream of scanned peripherals.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.scanInProgress`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil)
                    -> Observable<_ScannedPeripheral> {
        let observable: Observable<_ScannedPeripheral> = Observable.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(_BluetoothError.destroyed)
                return Disposables.create()
            }
            strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
            if strongSelf.scanDisposable != nil {
                observer.onError(_BluetoothError.scanInProgress)
                return Disposables.create()
            }
            strongSelf.scanDisposable = strongSelf.delegateWrapper.didDiscoverPeripheral
                    .flatMap { [weak self] (cbPeripheral, advertisment, rssi) -> Observable<_ScannedPeripheral> in
                        guard let strongSelf = self else {
                            throw _BluetoothError.destroyed
                        }
                        let peripheral = strongSelf.retrievePeripheral(for: cbPeripheral)
                        let advertismentData = AdvertisementData(advertisementData: advertisment)
                        return .just(_ScannedPeripheral(peripheral: peripheral,
                                advertisementData: advertismentData, rssi: rssi))
                    }
                    .subscribe(observer)

            strongSelf.manager.scanForPeripherals(withServices: serviceUUIDs, options: options)

            return Disposables.create { [weak self] in
                guard let strongSelf = self else { return }
                // When disposed, stop scan and dispose scanning
                if strongSelf.state == .poweredOn {
                    strongSelf.manager.stopScan()
                }
                do { strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                    strongSelf.scanDisposable?.dispose()
                    strongSelf.scanDisposable = nil
                }
            }
        }

        return ensure(.poweredOn, observable: observable)
    }

    // MARK: _Peripheral's Connection Management

    /// Establishes connection with a given `_Peripheral`.
    /// When connection did succeded it sends event with `_Peripheral` - from now on it is possible to call all other methods that require connection.
    /// The connection is automatically disconnected when resulting Observable is unsubscribed.
    /// On the other hand when the connection is interrupted or failed by the device or the system, the Observable will be unsubscribed as well
    /// following `_BluetoothError.peripheralConnectionFailed` or `_BluetoothError.peripheralDisconnected` emission.
    /// Additionally you can pass optional [dictionary](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Connection_Options)
    /// to customise the behaviour of connection.
    ///
    /// - parameter peripheral: The `_Peripheral` to which `_CentralManager` is attempting to establish connection.
    /// - parameter options: Dictionary to customise the behaviour of connection.
    /// - returns: `Observable` which emits next event after connection is established.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.peripheralIsAlreadyObservingConnection`
    /// * `_BluetoothError.peripheralConnectionFailed`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func establishConnection(_ peripheral: _Peripheral, options: [String: Any]? = nil) -> Observable<_Peripheral> {
        let observable = connector.establishConnection(with: peripheral, options: options)
        return ensure(.poweredOn, observable: observable)
    }

    // MARK: Retrieving Lists of Peripherals

    /// Returns list of the `_Peripheral`s which are currently connected to the `_CentralManager` and contain
    /// all of the specified `_Service`'s UUIDs.
    ///
    /// - parameter serviceUUIDs: A list of `_Service` UUIDs
    /// - returns: Retrieved `_Peripheral`s. They are in connected state and contain all of the
    /// `_Service`s with UUIDs specified in the `serviceUUIDs` parameter.
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [_Peripheral] {
        return manager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
            .map { self.retrievePeripheral(for: $0) }
    }

    /// Returns list of `_Peripheral`s by their identifiers which are known to `_CentralManager`.
    ///
    /// - parameter identifiers: List of `_Peripheral`'s identifiers which should be retrieved.
    /// - returns: Retrieved `_Peripheral`s.
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [_Peripheral] {
        return manager.retrievePeripherals(withIdentifiers: identifiers)
            .map { self.retrievePeripheral(for: $0) }
    }

    // MARK: Connection and disconnection observing

    /// Emits `_Peripheral` instance when it's connected.
    ///
    /// - parameter peripheral: Optional `_Peripheral` which is observed for connection. When not specified it will observe fo any `_Peripheral`.
    /// - returns: Observable which emits next events when `peripheral` was connected.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeConnect(for peripheral: _Peripheral? = nil) -> Observable<_Peripheral> {
        let observable = delegateWrapper.didConnectPeripheral
            .filter { peripheral != nil ? ($0 == peripheral!.peripheral) : true }
            .map { [weak self] (cbPeripheral: CBPeripheralMock) -> _Peripheral in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                return peripheral ?? strongSelf.retrievePeripheral(for: cbPeripheral)
            }
      return ensure(.poweredOn, observable: observable)
    }

    /// Emits `_Peripheral` instance when it's disconnected.
    /// - parameter peripheral: Optional `_Peripheral` which is observed for disconnection. When not specified it will observe for any `_Peripheral`.
    /// - returns: Observable which emits next events when `_Peripheral` instance was disconnected.
    /// It provides optional error which may contain more information about the cause of the disconnection
    /// if it wasn't the `cancelPeripheralConnection` call.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeDisconnect(for peripheral: _Peripheral? = nil) -> Observable<(_Peripheral, DisconnectionReason?)> {
        let observable = delegateWrapper.didDisconnectPeripheral
            .filter { peripheral != nil ? ($0.0 == peripheral!.peripheral) : true }
            .map { [weak self] (cbPeripheral, error) -> (_Peripheral, DisconnectionReason?) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                let peripheral = peripheral ?? strongSelf.retrievePeripheral(for: cbPeripheral)
                return (peripheral, error)
            }
        return ensure(.poweredOn, observable: observable)
                .catch { error in
                    if error is _BluetoothError, let peripheral = peripheral {
                        return .concat(.just((peripheral, error)), .error(error))
                    } else {
                        return .error(error)
                    }
                }
    }

    // MARK: ANCS

    /// Emits boolean values according to ancsAuthorized property on a CBPeripheralMock.
    ///
    /// - parameter peripheral: `_Peripheral` which is observed for ancsAuthorized chances.
    /// - returns: Observable which emits next events when `ancsAuthorized` property changes on a peripheral.
    #if !os(macOS)
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func observeANCSAuthorized(for peripheral: _Peripheral) -> Observable<Bool> {
        let observable = delegateWrapper.didUpdateANCSAuthorizationForPeripheral
            .asObservable()
            .filter { $0 == peripheral.peripheral }
            // ancsAuthorized is a Bool by default, but the testing framework
            // will use Bool! instead. In order to support that we are converting
            // to optional and unwrapping the value.
            .map { ($0.ancsAuthorized as Bool?)! }

        return ensure(.poweredOn, observable: observable)
    }
    #endif

    // MARK: Internal functions

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

    func retrievePeripheral(for cbPeripheral: CBPeripheralMock) -> _Peripheral {
        return peripheralProvider.provide(for: cbPeripheral, centralManager: self)
    }
}
