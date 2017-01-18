import RxSwift

protocol BluetoothStateProvider {
    /// Observable which emits state changes of central manager after subscriptions
    var rx_didUpdateState: Observable<BluetoothState> { get }

    /// Current state of Central Manager
    var state: BluetoothState { get }
}

protocol BluetoothStateManager {
    var stateProvider: BluetoothStateProvider { get }
}

extension BluetoothStateManager {
    // MARK: State

    //TODO: Docs to change...
    /**
     Continuous state of `CentralManager` instance described by `BluetoothState` which is equivalent to  [`CBManagerState`](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).

     - returns: Observable that emits `Next` immediately after subscribtion with current state of Bluetooth. Later,
     whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
     */
    public var rx_state: Observable<BluetoothState> {
        return .deferred {
            return self.stateProvider.rx_didUpdateState.startWith(self.stateProvider.state)
        }
    }

    /**
     Current state of `CentralManager` instance described by `BluetoothState` which is equivalent to [`CBManagerState`](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).

     - returns: Current state of `CentralManager` as `BluetoothState`.
     */

    public var state: BluetoothState {
        return self.stateProvider.state
    }
}
