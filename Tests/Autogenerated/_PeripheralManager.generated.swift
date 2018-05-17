import Foundation
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

class _PeripheralManager: _ManagerType {

    let manager: CBPeripheralManagerMock

    let delegateWrapper: CBPeripheralManagerDelegateWrapperMock

    /// Lock for checking advertising state
    private let advertisingLock = NSLock()
    /// Is there ongoing advertising
    var isAdvertisingOngoing = false
    var restoredAdvertisementData: RestoredAdvertisementData?

    // MARK: Initialization

    /// Creates new `_PeripheralManager`
    /// - parameter peripheralManager: `CBPeripheralManagerMock` instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's peripheral manager callbacks.
    init(peripheralManager: CBPeripheralManagerMock, delegateWrapper: CBPeripheralManagerDelegateWrapperMock) {
        self.manager = peripheralManager
        self.delegateWrapper = delegateWrapper
        peripheralManager.delegate = delegateWrapper
    }

    /// Creates new `_PeripheralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a peripheral manager.
    /// For more info about it please refer to [_Peripheral Manager initialization options](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/peripheral_manager_initialization_options)
    convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil) {
        let delegateWrapper = CBPeripheralManagerDelegateWrapperMock()
        #if os(iOS) || os(macOS)
        let peripheralManager = CBPeripheralManagerMock(delegate: delegateWrapper, queue: queue, options: options)
        #else
        let peripheralManager = CBPeripheralManagerMock()
        peripheralManager.delegate = delegateWrapper
        #endif
        self.init(peripheralManager: peripheralManager, delegateWrapper: delegateWrapper)
    }

    // MARK: State

    var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unsupported
    }

    func observeState() -> Observable<BluetoothState> {
        return self.delegateWrapper.didUpdateState.asObservable()
    }

    // MARK: Advertising

    func startAdvertising(_ advertisementData: [String: Any]?) -> Observable<StartAdvertisingResult> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            let observable: Observable<StartAdvertisingResult> = Observable.create { [weak self] observer in
                guard let strongSelf = self else {
                    observer.onError(_BluetoothError.destroyed)
                    return Disposables.create()
                }
                strongSelf.advertisingLock.lock(); defer { strongSelf.advertisingLock.unlock() }
                if strongSelf.isAdvertisingOngoing {
                    observer.onError(_BluetoothError.advertisingInProgress)
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
                                throw _BluetoothError.advertisingStartFailed(error)
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

    func add(_ service: CBMutableService) -> Single<CBServiceMock> {
        let observable = delegateWrapper
            .didAddService
            .filter { $0.0 == service }
            .take(1)
            .map { (cbService, error) -> (CBServiceMock) in
                if let error = error {
                    throw _BluetoothError.addingServiceFailed(cbService, error)
                }
                return cbService
            }
        return ensureValidStateAndCallIfSucceeded(for: observable) {
            [weak self] in
            self?.manager.add(service)
        }.asSingle()
    }

    func remove(_ service: CBMutableService) {
        manager.remove(service)
    }

    func removeAllServices() {
        manager.removeAllServices()
    }

    // MARK: Read & Write

    func observeDidReceiveRead() -> Observable<CBATTRequest> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveRead)
    }

    func observeDidReceiveWrite() -> Observable<[CBATTRequest]> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveWrite)
    }

    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        manager.respond(to: request, withResult: result)
    }

    // MARK: Updating value

    func updateValue(
        _ value: Data,
        for characteristic: CBMutableCharacteristic,
        onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        return manager.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }

    func observeIsReadyToUpdateSubscribers() -> Observable<Void> {
        return ensure(.poweredOn, observable: delegateWrapper.isReady)
    }

    // MARK: Subscribing

    func observeOnSubscribe() -> Observable<(CBCentral, CBCharacteristicMock)> {
        return ensure(.poweredOn, observable: delegateWrapper.didSubscribeTo)
    }

    func observeOnUnsubscribe() -> Observable<(CBCentral, CBCharacteristicMock)> {
        return ensure(.poweredOn, observable: delegateWrapper.didUnsubscribeFrom)
    }

    // MARK: Internal functions

    func ensureValidStateAndCallIfSucceeded<T>(for observable: Observable<T>,
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
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool) -> Observable<CBL2CAPPSM> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            let observable: Observable<CBL2CAPPSM> = Observable.create { [weak self] observer in
                guard let strongSelf = self else {
                    observer.onError(_BluetoothError.destroyed)
                    return Disposables.create()
                }

                var result: CBL2CAPPSM? = nil
                let disposable = strongSelf.delegateWrapper.didPublishL2CAPChannel
                    .take(1)
                    .map { (cbl2cappSm, error) -> (CBL2CAPPSM) in
                        if let error = error {
                            throw _BluetoothError.publishingL2CAPChanngelFailed(cbl2cappSm, error)
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
    func observeDidOpenL2CAPChannel() -> Observable<(CBL2CAPChannelMock?, Error?)> {
        return ensure(.poweredOn, observable: delegateWrapper.didOpenChannel)
    }
    #endif
}
