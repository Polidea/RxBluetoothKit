import Foundation
import CoreBluetooth
import RxSwift

//TODO: We should introduce ConnectedPeripheral type
protocol PeripheralType {

    associatedtype S
    associatedtype C
    associatedtype D

    var name: String? { get }

    var identifier: UUID { get }

    var state: BluetoothState { get }

    var services: [S]? { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: S)

    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: S)

    func readValue(for characteristic: C)

    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

    func writeValue(_ data: Data,
                    for characteristic: C,
                    type: CBCharacteristicWriteType)

    func setNotifyValue(_ enabled: Bool, for characteristic: C)

    func discoverDescriptors(for characteristic: C)

    func readValue(for descriptor: D)

    func writeValue(_ data: Data, for descriptor: D)

    func readRSSI()
}

extension PeripheralType {

}
