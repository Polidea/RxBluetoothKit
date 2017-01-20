import RxSwift

protocol ManagerType {
    /// Observable which emits state changes of central manager after subscriptions
    var rx_didUpdateState: Observable<BluetoothState> { get }

    /// Current state of Central Manager
    var state: BluetoothState { get }
}

extension ManagerType {

    public var rx_state: Observable<BluetoothState> {
        return .deferred {
            return self.rx_didUpdateState.startWith(self.state)
        }
    }
    
    public var state: BluetoothState {
        return self.state
    }
}
