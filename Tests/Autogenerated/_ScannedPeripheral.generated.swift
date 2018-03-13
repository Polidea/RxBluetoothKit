import Foundation
import CoreBluetooth
@testable import RxBluetoothKit

/// Represents instance of scanned peripheral - containing it's advertisment data, rssi and peripheral itself.
/// To perform further actions `peripheral` instance variable can be used ia. to maintain connection.
class _ScannedPeripheral {

    /// `_Peripheral` instance, that allows to perform further bluetooth actions.
    let peripheral: _Peripheral

    /// Advertisement data of scanned peripheral
    let advertisementData: AdvertisementData

    /// Scanned peripheral's RSSI value.
    let rssi: NSNumber

    init(peripheral: _Peripheral, advertisementData: AdvertisementData, rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
}
