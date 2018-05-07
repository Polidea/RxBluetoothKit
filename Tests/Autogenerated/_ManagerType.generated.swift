import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

protocol _ManagerType {
    associatedtype Manager: CBManagerMock

    /// Implementation of CBManagerMock
    var manager: Manager { get }
    /// Current state of `_CentralManager` instance described by `BluetoothState` which is equivalent to
    /// [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    var state: BluetoothState { get }
}

extension _ManagerType {
    var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unsupported
    }
}
