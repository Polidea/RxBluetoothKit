import Foundation
import RxSwift
import CoreBluetooth

public protocol ManagerType {
    associatedtype Manager: CBManager

    /// Implementation of CBManager
    var manager: Manager { get }
    /// Current state of `CentralManager` instance described by `BluetoothState` which is equivalent to
    /// [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    var state: BluetoothState { get }
}

public extension ManagerType {
    var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unsupported
    }
}
