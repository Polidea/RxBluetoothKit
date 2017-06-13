import Foundation
import RxSwift
import CoreBluetooth

public final class Peripheral: PeripheralType {
    typealias S = Service
    typealias C = Characteristic
    typealias D = Descriptor
    
    public let cbPeripheral: CBPeripheral

    init(cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }

    public var name: String? {
        return cbPeripheral.name
    }

    public var identifier: UUID {
        return cbPeripheral.identifier
    }

    var state: CBPeripheralState {
        return cbPeripheral.state
    }

    var services: [Service]? {
        return cbPeripheral.services?.map(Service.init)
    }

    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        cbPeripheral.discoverServices(serviceUUIDs)
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) {
        cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service.cbService)
    }

    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) {
        cbPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service.cbService)
    }

    func readValue(for characteristic: Characteristic) {
        cbPeripheral.readValue(for: characteristic.cbCharacteristic)
    }

    @available(OSX 10.1, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return cbPeripheral.maximumWriteValueLength(for: type)
    }

    func writeValue(_ data: Data,
                    for characteristic: Characteristic,
                    type: CBCharacteristicWriteType) {
        cbPeripheral.writeValue(data, for: characteristic.cbCharacteristic, type: type)
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) {
        cbPeripheral.setNotifyValue(enabled, for: characteristic.cbCharacteristic)
    }

    func discoverDescriptors(for characteristic: Characteristic) {
        cbPeripheral.discoverDescriptors(for: characteristic.cbCharacteristic)
    }

    func readValue(for descriptor: Descriptor) {
        cbPeripheral.readValue(for: descriptor.cbDescriptor)
    }

    func writeValue(_ data: Data, for descriptor: Descriptor) {
        cbPeripheral.writeValue(data, for: descriptor.cbDescriptor)
    }

    func readRSSI() {
        cbPeripheral.readRSSI()
    }
}
