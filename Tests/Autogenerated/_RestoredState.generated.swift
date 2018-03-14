import Foundation
import CoreBluetooth
@testable import RxBluetoothKit

/// Convenience class which helps reading state of restored _CentralManager.
struct _RestoredState {

    /// Restored state dictionary.
    let restoredStateData: [String: Any]

    unowned let centralManager: _CentralManager
    /// Creates restored state information based on CoreBluetooth's dictionary
    /// - parameter restoredStateDictionary: Core Bluetooth's restored state data
    /// - parameter centralManager: `_CentralManager` instance of which state has been restored.
    init(restoredStateDictionary: [String: Any], centralManager: _CentralManager) {
        restoredStateData = restoredStateDictionary
        self.centralManager = centralManager
    }

    /// Array of `_Peripheral` objects which have been restored.
    /// These are peripherals that were connected to the central manager (or had a connection pending)
    /// at the time the app was terminated by the system.
    var peripherals: [_Peripheral] {
        let objects = restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }
        return arrayOfAnyObjects.flatMap { $0 as? CBPeripheralMock }
            .map { centralManager.retrievePeripheral(for: $0) }
    }

    /// Dictionary that contains all of the peripheral scan options that were being used
    /// by the central manager at the time the app was terminated by the system.
    var scanOptions: [String: AnyObject]? {
        return restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [String: AnyObject]
    }

    /// Array of `_Service` objects which have been restored.
    /// These are all the services the central manager was scanning for at the time the app
    /// was terminated by the system.
    var services: [_Service] {
        let objects = restoredStateData[CBCentralManagerRestoredStateScanServicesKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }
        return arrayOfAnyObjects.flatMap { $0 as? CBServiceMock }
            .map { _Service(peripheral: centralManager.retrievePeripheral(for: $0.peripheral),
                           service: $0) }
    }
}
