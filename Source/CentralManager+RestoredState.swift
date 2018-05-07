import Foundation
import RxSwift
import CoreBluetooth

/// Closure that receives `RestoredState` as a parameter
public typealias OnWillRestoreState = (RestoredState) -> Void

extension CentralManager {

    // MARK: State restoration

    /// Creates new `CentralManager` instance, which supports bluetooth state restoration.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread
    /// for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used
    /// and all operations and events are executed and received on main thread.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    /// - parameter onWillRestoreState: Closure called when state has been restored.
    ///
    /// - seealso: `RestoredState`
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            onWillRestoreState: OnWillRestoreState? = nil) {
        self.init(queue: queue, options: options)
        if let onWillRestoreState = onWillRestoreState {
            listenOnWillRestoreState(onWillRestoreState)
        }
    }

    // swiftlint:enable line_length

    /// Creates new `CentralManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    /// - parameter peripheralProvider: Provider for providing peripherals and peripheral wrappers
    /// - parameter connector: Connector instance which is used for establishing connection with peripherals
    /// - parameter onWillRestoreState: Closure called when state has been restored.
    convenience init(
        centralManager: CBCentralManager,
        delegateWrapper: CBCentralManagerDelegateWrapper,
        peripheralProvider: PeripheralProvider,
        connector: Connector,
        onWillRestoreState: @escaping OnWillRestoreState
    ) {
        self.init(
            centralManager: centralManager,
            delegateWrapper: delegateWrapper,
            peripheralProvider: peripheralProvider,
            connector: connector
        )
        listenOnWillRestoreState(onWillRestoreState)
    }

    /// Emits `RestoredState` instance, when state of `CentralManager` has been restored,
    /// Should only be called once in the lifetime of the app
    /// - returns: Observable which emits next events state has been restored
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreState) {
        _ = delegateWrapper
            .willRestoreState
            .take(1)
            .flatMap { [weak self] dict -> Observable<RestoredState> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return .just(RestoredState(restoredStateDictionary: dict, centralManager: strongSelf))
            }
            .subscribe(onNext: { handler($0) })
    }
}
