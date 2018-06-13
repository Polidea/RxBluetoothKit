import Foundation
import CoreBluetooth
@testable import RxBluetoothKit

/// Deprecated, use _CentralManager.init(queue:options:onWillRestoreCentralManagerState:) instead
@available(*, deprecated: 5.1.0, renamed: "CentralManagerRestoredStateType")
struct _RestoredState: CentralManagerRestoredStateType {
    let centralManagerRestoredState: _CentralManagerRestoredState

    var restoredStateData: [String: Any] { return centralManagerRestoredState.restoredStateData }

    var centralManager: _CentralManager { return centralManagerRestoredState.centralManager }

    var peripherals: [_Peripheral] { return centralManagerRestoredState.peripherals }

    var scanOptions: [String: AnyObject]? { return centralManagerRestoredState.scanOptions }

    var services: [_Service] { return centralManagerRestoredState.services }

    init(centralManagerRestoredState: _CentralManagerRestoredState) {
        self.centralManagerRestoredState = centralManagerRestoredState
    }
}
