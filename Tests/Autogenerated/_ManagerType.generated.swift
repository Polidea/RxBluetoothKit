import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

protocol _ManagerType: AnyObject {
    associatedtype Manager

    /// Implementation of CBManagerMock
    var manager: Manager { get }
    /// Current state of `_CentralManager` instance described by `BluetoothState` which is equivalent to
    /// [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    var state: BluetoothState { get }

    /// Continuous state of `CBManagerMock` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    /// - returns: Observable that emits `next` event whenever state changes.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    func observeState() -> Observable<BluetoothState>

    /// Continuous state of `CBManagerMock` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    /// - returns: Observable that emits `next` event starting with current state and whenever state changes.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    func observeStateWithInitialValue() -> Observable<BluetoothState>
}

extension _ManagerType {
    /// Ensure that `state` is and will be the only state of `_CentralManager` during subscription.
    /// Otherwise error is emitted.
    /// - parameter state: `BluetoothState` which should be present during subscription.
    /// - parameter observable: Observable into which potential errors should be merged.
    /// - returns: New observable which merges errors with source observable.
    func ensure<T>(_ state: BluetoothState, observable: Observable<T>) -> Observable<T> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            let statesObservable = strongSelf.observeStateWithInitialValue()
                .filter { $0 != state && _BluetoothError(state: $0) != nil }
                .map { state -> T in throw _BluetoothError(state: state)! }
            return .absorb(statesObservable, observable)
        }
    }
}
