import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

@available(*, deprecated: 5.1.0, renamed: "OnWillRestoreCentralManagerState")
typealias OnWillRestoreState = (_RestoredState) -> Void
/// Closure that receives `_RestoredState` as a parameter
typealias OnWillRestoreCentralManagerState = (_CentralManagerRestoredState) -> Void

extension _CentralManager {

    // MARK: State restoration

    /// Deprecated, use _CentralManager.init(queue:options:onWillRestoreCentralManagerState:) instead
    @available(*, deprecated: 5.1.0, renamed: "_CentralManager.init(queue:options:onWillRestoreCentralManagerState:)")
    convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            onWillRestoreState: OnWillRestoreState? = nil) {
        self.init(queue: queue, options: options)
        if let onWillRestoreState = onWillRestoreState {
            listenOnWillRestoreState(onWillRestoreState)
        }
    }

    /// Creates new `_CentralManager` instance, which supports bluetooth state restoration.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread
    /// for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used
    /// and all operations and events are executed and received on main thread.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    /// - parameter onWillRestoreCentralManagerState: Closure called when state has been restored.
    ///
    /// - seealso: `OnWillRestoreCentralManagerState`
    convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            onWillRestoreCentralManagerState: OnWillRestoreCentralManagerState? = nil) {
        self.init(queue: queue, options: options)
        if let onWillRestoreCentralManagerState = onWillRestoreCentralManagerState {
            listenOnWillRestoreState(onWillRestoreCentralManagerState)
        }
    }

    /// Creates new `_CentralManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    /// - parameter peripheralProvider: Provider for providing peripherals and peripheral wrappers
    /// - parameter connector: ConnectorMock instance which is used for establishing connection with peripherals
    /// - parameter onWillRestoreState: Closure called when state has been restored.
    convenience init(
        centralManager: CBCentralManagerMock,
        delegateWrapper: CBCentralManagerDelegateWrapperMock,
        peripheralProvider: PeripheralProviderMock,
        connector: ConnectorMock,
        onWillRestoreCentralManagerState: @escaping OnWillRestoreCentralManagerState
        ) {
        self.init(
            centralManager: centralManager,
            delegateWrapper: delegateWrapper,
            peripheralProvider: peripheralProvider,
            connector: connector
        )
        listenOnWillRestoreState(onWillRestoreCentralManagerState)
    }

    @available(*, deprecated: 5.1.0, message: "listenOnWillRestoreState(:OnWillRestoreCentralManagerState) instead")
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreState) {
        _ = restoreStateObservable
            .map { _RestoredState(centralManagerRestoredState: $0) }
            .subscribe(onNext: { handler($0) })
    }

    /// Emits `_RestoredState` instance, when state of `_CentralManager` has been restored,
    /// Should only be called once in the lifetime of the app
    /// - returns: Observable which emits next events state has been restored
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreCentralManagerState) {
        _ = restoreStateObservable
            .subscribe(onNext: { handler($0) })
    }

    var restoreStateObservable: Observable<_CentralManagerRestoredState> {
        return delegateWrapper
            .willRestoreState
            .take(1)
            .flatMap { [weak self] dict -> Observable<_CentralManagerRestoredState> in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                return .just(_CentralManagerRestoredState(restoredStateDictionary: dict, centralManager: strongSelf))
            }
    }
}
