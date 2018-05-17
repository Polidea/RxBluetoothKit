import Foundation
import CoreBluetooth
import RxSwift

class PeripheralManager: ManagerType {

    public let manager: CBPeripheralManager

    let delegateWrapper: CBPeripheralManagerDelegateWrapper

    /// Lock for checking advertising state
    private let advertisingLock = NSLock()
    /// Is there ongoing advertising
    var isAdvertisingOngoing = false
    var restoredAdvertisementData: RestoredAdvertisementData?

    // MARK: Initialization

    /// Creates new `PeripheralManager`
    /// - parameter peripheralManager: `CBPeripheralManager` instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's peripheral manager callbacks.
    init(peripheralManager: CBPeripheralManager, delegateWrapper: CBPeripheralManagerDelegateWrapper) {
        self.manager = peripheralManager
        self.delegateWrapper = delegateWrapper
        peripheralManager.delegate = delegateWrapper
    }

    /// Creates new `PeripheralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a peripheral manager.
    /// For more info about it please refer to [Peripheral Manager initialization options](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/peripheral_manager_initialization_options)
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil) {
        let delegateWrapper = CBPeripheralManagerDelegateWrapper()
        #if os(iOS) || os(macOS)
        let peripheralManager = CBPeripheralManager(delegate: delegateWrapper, queue: queue, options: options)
        #else
        let peripheralManager = CBPeripheralManager()
        peripheralManager.delegate = delegateWrapper
        #endif
        self.init(peripheralManager: peripheralManager, delegateWrapper: delegateWrapper)
    }

    // MARK: State

    public var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unsupported
    }

    public func observeState() -> Observable<BluetoothState> {
        return self.delegateWrapper.didUpdateState.asObservable()
    }

    // MARK: Advertising

    public func startAdvertising(_ advertisementData: [String: Any]?) -> Observable<StartAdvertisingResult> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw BluetoothError.destroyed }
            let observable: Observable<StartAdvertisingResult> = Observable.create { [weak self] observer in
                guard let strongSelf = self else {
                    observer.onError(BluetoothError.destroyed)
                    return Disposables.create()
                }
                strongSelf.advertisingLock.lock(); defer { strongSelf.advertisingLock.unlock() }
                if strongSelf.isAdvertisingOngoing {
                    observer.onError(BluetoothError.advertisingInProgress)
                    return Disposables.create()
                }

                strongSelf.isAdvertisingOngoing = true

                var disposable: Disposable? = nil
                if strongSelf.manager.isAdvertising {
                    observer.onNext(.ongoing(strongSelf.restoredAdvertisementData))
                    strongSelf.restoredAdvertisementData = nil
                } else {
                    disposable = strongSelf.delegateWrapper.didStartAdvertising
                        .take(1)
                        .map { error in
                            if let error = error {
                                throw BluetoothError.advertisingStartFailed(error)
                            }
                            return .started
                        }
                        .subscribe(onNext: { observer.onNext($0) }, onError: { observer.onError($0)})
                    strongSelf.manager.startAdvertising(advertisementData)
                }
                return Disposables.create { [weak self] in
                    guard let strongSelf = self else { return }
                    disposable?.dispose()
                    strongSelf.manager.stopAdvertising()
                    do { strongSelf.advertisingLock.lock(); defer { strongSelf.advertisingLock.unlock() }
                        strongSelf.isAdvertisingOngoing = false
                    }
                }
            }
            return strongSelf.ensure(.poweredOn, observable: observable)
        }
    }

    // MARK: Services

    public func add(_ service: CBMutableService) -> Single<CBService> {
        let observable = delegateWrapper
            .didAddService
            .filter { $0.0 == service }
            .take(1)
            .map { (cbService, error) -> (CBService) in
                if let error = error {
                    throw BluetoothError.addingServiceFailed(cbService, error)
                }
                return cbService
            }
        return ensureValidStateAndCallIfSucceeded(for: observable) {
            [weak self] in
            self?.manager.add(service)
        }.asSingle()
    }

    public func remove(_ service: CBMutableService) {
        manager.remove(service)
    }

    public func removeAllServices() {
        manager.removeAllServices()
    }

    // MARK: Read & Write

    public func observeDidReceiveRead() -> Observable<CBATTRequest> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveRead)
    }

    public func observeDidReceiveWrite() -> Observable<[CBATTRequest]> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveWrite)
    }

    public func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        manager.respond(to: request, withResult: result)
    }

    // MARK: Updating value

    public func updateValue(
        _ value: Data,
        for characteristic: CBMutableCharacteristic,
        onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        return manager.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }

    public func observeIsReadyToUpdateSubscribers() -> Observable<Void> {
        return ensure(.poweredOn, observable: delegateWrapper.isReady)
    }

    // MARK: Subscribing

    public func observeOnSubscribe() -> Observable<(CBCentral, CBCharacteristic)> {
        return ensure(.poweredOn, observable: delegateWrapper.didSubscribeTo)
    }

    public func observeOnUnsubscribe() -> Observable<(CBCentral, CBCharacteristic)> {
        return ensure(.poweredOn, observable: delegateWrapper.didUnsubscribeFrom)
    }

    // MARK: Internal functions

    public func ensureValidStateAndCallIfSucceeded<T>(for observable: Observable<T>,
                                                      postSubscriptionCall call: @escaping () -> Void
        ) -> Observable<T> {
        let operation = Observable<T>.deferred {
            call()
            return .empty()
        }
        return ensure(.poweredOn, observable: Observable.merge([observable, operation]))
    }

    // MARK: L2CAP

    #if os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 11, tvOS 11, watchOS 4, *)
    public func publishL2CAPChannel(withEncryption encryptionRequired: Bool) -> Observable<CBL2CAPPSM> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw BluetoothError.destroyed }
            let observable: Observable<CBL2CAPPSM> = Observable.create { [weak self] observer in
                guard let strongSelf = self else {
                    observer.onError(BluetoothError.destroyed)
                    return Disposables.create()
                }

                var result: CBL2CAPPSM? = nil
                let disposable = strongSelf.delegateWrapper.didPublishL2CAPChannel
                    .take(1)
                    .map { (cbl2cappSm, error) -> (CBL2CAPPSM) in
                        if let error = error {
                            throw BluetoothError.publishingL2CAPChanngelFailed(cbl2cappSm, error)
                        }
                        result = cbl2cappSm
                        return cbl2cappSm
                    }
                    .subscribe(onNext: { observer.onNext($0) }, onError: { observer.onError($0)})
                strongSelf.manager.publishL2CAPChannel(withEncryption: encryptionRequired)
                return Disposables.create { [weak self] in
                    guard let strongSelf = self else { return }
                    disposable.dispose()
                    if let result = result {
                        strongSelf.manager.unpublishL2CAPChannel(result)
                    }
                }
            }
            return strongSelf.ensure(.poweredOn, observable: observable)
        }
    }

    @available(iOS 11, tvOS 11, watchOS 4, *)
    public func observeDidOpenL2CAPChannel() -> Observable<(CBL2CAPChannel?, Error?)> {
        return ensure(.poweredOn, observable: delegateWrapper.didOpenChannel)
    }
    #endif
}
