import Foundation
import CoreBluetooth
@testable import RxBluetoothKit

/// It should be deleted when `_RestoredState` will be deleted
protocol CentralManagerRestoredStateType {
    var restoredStateData: [String: Any] { get }
    var centralManager: _CentralManager { get }
    var peripherals: [_Peripheral] { get }
    var scanOptions: [String: AnyObject]? { get }
    var services: [_Service] { get }
}

/// Convenience class which helps reading state of restored _CentralManager.
struct _CentralManagerRestoredState: CentralManagerRestoredStateType {

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

        #if swift(>=4.1)
        let cbPeripherals = arrayOfAnyObjects.compactMap { $0 as? CBPeripheralMock }
        #else
        let cbPeripherals = arrayOfAnyObjects.flatMap { $0 as? CBPeripheralMock }
        #endif

        return cbPeripherals.map { centralManager.retrievePeripheral(for: $0) }
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

        #if swift(>=4.1)
        let cbServices = arrayOfAnyObjects.compactMap { $0 as? CBServiceMock }
        #else
        let cbServices = arrayOfAnyObjects.flatMap { $0 as? CBServiceMock }
        #endif

        return cbServices.compactMap {
            guard let cbPeripheral = $0.peripheral else { return nil }
            let peripheral = centralManager.retrievePeripheral(for: cbPeripheral)
            return _Service(peripheral: peripheral, service: $0)
        }
    }
}
