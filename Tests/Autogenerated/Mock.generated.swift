// Generated using Sourcery 0.10.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import CoreBluetooth
@testable
import RxBluetoothKit

class CBCentralManagerMock: NSObject {
    var delegate: _CBCentralManagerDelegate?
    var isScanning: Bool!
    var state: CBManagerState!

    init(delegate: _CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
    }

    var retrievePeripheralsParams: [([UUID])] = []
    var retrievePeripheralsReturns: [[CBPeripheralMock]] = []
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralMock] {
        retrievePeripheralsParams.append((identifiers))
        if retrievePeripheralsReturns.isEmpty {
            fatalError("No return value")
        } else {
            return retrievePeripheralsReturns.removeFirst()
        }
    }

    var retrieveConnectedPeripheralsParams: [([CBUUID])] = []
    var retrieveConnectedPeripheralsReturns: [[CBPeripheralMock]] = []
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralMock] {
        retrieveConnectedPeripheralsParams.append((serviceUUIDs))
        if retrieveConnectedPeripheralsReturns.isEmpty {
            fatalError("No return value")
        } else {
            return retrieveConnectedPeripheralsReturns.removeFirst()
        }
    }

    var scanForPeripheralsParams: [([CBUUID]?, [String : Any]?)] = []
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        scanForPeripheralsParams.append((serviceUUIDs, options))
    }

    var stopScanParams: [()] = []
    func stopScan() {
        stopScanParams.append(())
    }

    var connectParams: [(CBPeripheralMock, [String : Any]?)] = []
    func connect(_ peripheral: CBPeripheralMock, options: [String : Any]? = nil) {
        connectParams.append((peripheral, options))
    }

    var cancelPeripheralConnectionParams: [(CBPeripheralMock)] = []
    func cancelPeripheralConnection(_ peripheral: CBPeripheralMock) {
        cancelPeripheralConnectionParams.append((peripheral))
    }

}

extension CBCentralManagerMock: Loggable {
    @objc var logDescription: String {
        return "CBCentralManagerMock"
    }
}

class CBPeripheralMock: NSObject {
    var delegate: _CBPeripheralDelegate?
    var name: String?
    var rssi: NSNumber?
    var state: CBPeripheralState!
    var services: [CBServiceMock]?
    var canSendWriteWithoutResponse: Bool!
    var identifier: UUID!

    override init() {
    }

    var readRSSIParams: [()] = []
    func readRSSI() {
        readRSSIParams.append(())
    }

    var discoverServicesParams: [([CBUUID]?)] = []
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesParams.append((serviceUUIDs))
    }

    var discoverIncludedServicesParams: [([CBUUID]?, CBServiceMock)] = []
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBServiceMock) {
        discoverIncludedServicesParams.append((includedServiceUUIDs, service))
    }

    var discoverCharacteristicsParams: [([CBUUID]?, CBServiceMock)] = []
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceMock) {
        discoverCharacteristicsParams.append((characteristicUUIDs, service))
    }

    var readValueWithCharacteristicParams: [(CBCharacteristicMock)] = []
    func readValue(for characteristic: CBCharacteristicMock) {
        readValueWithCharacteristicParams.append((characteristic))
    }

    var maximumWriteValueLengthParams: [(CBCharacteristicWriteType)] = []
    var maximumWriteValueLengthReturns: [Int] = []
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        maximumWriteValueLengthParams.append((type))
        if maximumWriteValueLengthReturns.isEmpty {
            fatalError("No return value")
        } else {
            return maximumWriteValueLengthReturns.removeFirst()
        }
    }

    var writeValueWithTypeParams: [(Data, CBCharacteristicMock, CBCharacteristicWriteType)] = []
    func writeValue(_ data: Data, for characteristic: CBCharacteristicMock, type: CBCharacteristicWriteType) {
        writeValueWithTypeParams.append((data, characteristic, type))
    }

    var setNotifyValueParams: [(Bool, CBCharacteristicMock)] = []
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicMock) {
        setNotifyValueParams.append((enabled, characteristic))
    }

    var discoverDescriptorsParams: [(CBCharacteristicMock)] = []
    func discoverDescriptors(for characteristic: CBCharacteristicMock) {
        discoverDescriptorsParams.append((characteristic))
    }

    var readValueWithDescriptorParams: [(CBDescriptorMock)] = []
    func readValue(for descriptor: CBDescriptorMock) {
        readValueWithDescriptorParams.append((descriptor))
    }

    var writeValueWithDescriptorParams: [(Data, CBDescriptorMock)] = []
    func writeValue(_ data: Data, for descriptor: CBDescriptorMock) {
        writeValueWithDescriptorParams.append((data, descriptor))
    }

    var openL2CAPChannelParams: [(CBL2CAPPSM)] = []
    func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        openL2CAPChannelParams.append((PSM))
    }

}

extension CBPeripheralMock: Loggable {
    @objc var logDescription: String {
        return "CBPeripheralMock"
    }
}

class CBDescriptorMock: NSObject {
    var characteristic: CBCharacteristicMock!
    var value: Any?
    var uuid: CBUUID!

    override init() {
    }

}

extension CBDescriptorMock: Loggable {
    @objc var logDescription: String {
        return "CBDescriptorMock"
    }
}

class CBServiceMock: NSObject {
    var peripheral: CBPeripheralMock!
    var isPrimary: Bool!
    var includedServices: [CBServiceMock]?
    var characteristics: [CBCharacteristicMock]?
    var uuid: CBUUID!

    override init() {
    }

}

extension CBServiceMock: Loggable {
    @objc var logDescription: String {
        return "CBServiceMock"
    }
}

class CBCharacteristicMock: NSObject {
    var service: CBServiceMock!
    var properties: CBCharacteristicProperties!
    var value: Data?
    var descriptors: [CBDescriptorMock]?
    var isBroadcasted: Bool!
    var isNotifying: Bool!
    var uuid: CBUUID!

    override init() {
    }

}

extension CBCharacteristicMock: Loggable {
    @objc var logDescription: String {
        return "CBCharacteristicMock"
    }
}

class CBL2CAPChannelMock: NSObject {
    var peer: CBPeerMock?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var psm: CBL2CAPPSM!

    override init() {
    }

}

extension CBL2CAPChannelMock: Loggable {
    @objc var logDescription: String {
        return "CBL2CAPChannelMock"
    }
}

class CBPeerMock: NSObject {
    var identifier: UUID!

    override init() {
    }

}

extension CBPeerMock: Loggable {
    @objc var logDescription: String {
        return "CBPeerMock"
    }
}


protocol _CBPeripheralDelegate : NSObjectProtocol {
     
    func peripheralDidUpdateName(_ peripheral: CBPeripheralMock)
     
    func peripheral(_ peripheral: CBPeripheralMock, didModifyServices invalidatedServices: [CBServiceMock])
     
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheralMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didReadRSSI RSSI: NSNumber, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didDiscoverServices error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didDiscoverIncludedServicesFor service: CBServiceMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didDiscoverCharacteristicsFor service: CBServiceMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didUpdateValueFor characteristic: CBCharacteristicMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didWriteValueFor characteristic: CBCharacteristicMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didUpdateNotificationStateFor characteristic: CBCharacteristicMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didDiscoverDescriptorsFor characteristic: CBCharacteristicMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didUpdateValueFor descriptor: CBDescriptorMock, error: Error?)
     
    func peripheral(_ peripheral: CBPeripheralMock, didWriteValueFor descriptor: CBDescriptorMock, error: Error?)
     
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheralMock)
     
    func peripheral(_ peripheral: CBPeripheralMock, didOpen channel: CBL2CAPChannelMock?, error: Error?)
}
protocol _CBCentralManagerDelegate : NSObjectProtocol {
     
    func centralManagerDidUpdateState(_ central: CBCentralManagerMock)
     
    func centralManager(_ central: CBCentralManagerMock, willRestoreState dict: [String : Any])
     
    func centralManager(_ central: CBCentralManagerMock, didDiscover peripheral: CBPeripheralMock, advertisementData: [String : Any], rssi RSSI: NSNumber)
     
    func centralManager(_ central: CBCentralManagerMock, didConnect peripheral: CBPeripheralMock)
     
    func centralManager(_ central: CBCentralManagerMock, didFailToConnect peripheral: CBPeripheralMock, error: Error?)
     
    func centralManager(_ central: CBCentralManagerMock, didDisconnectPeripheral peripheral: CBPeripheralMock, error: Error?)
}



