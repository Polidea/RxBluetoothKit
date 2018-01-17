// Generated using Sourcery 0.10.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import CoreBluetooth
@testable
import RxBluetoothKit
import RxSwift

// MARK: - generated class mocks

class CBCentralManagerMock: NSObject {
    var delegate: CBCentralManagerDelegate?
    var isScanning: Bool!
    var logDescription: String!
    var state: CBManagerState!

    override init() {
    }
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
    }

    var retrievePeripheralsParams: [([UUID])] = []
    var retrievePeripheralsReturns: [[CBPeripheralMock]] = []
    var retrievePeripheralsReturn: [CBPeripheralMock]?
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralMock] {
        retrievePeripheralsParams.append((identifiers))
        if retrievePeripheralsReturns.isEmpty {
            return retrievePeripheralsReturn!
        } else {
            return retrievePeripheralsReturns.removeFirst()
        }
    }

    var retrieveConnectedPeripheralsParams: [([CBUUID])] = []
    var retrieveConnectedPeripheralsReturns: [[CBPeripheralMock]] = []
    var retrieveConnectedPeripheralsReturn: [CBPeripheralMock]?
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralMock] {
        retrieveConnectedPeripheralsParams.append((serviceUUIDs))
        if retrieveConnectedPeripheralsReturns.isEmpty {
            return retrieveConnectedPeripheralsReturn!
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
class CBPeripheralMock: NSObject {
    var delegate: CBPeripheralDelegate?
    var name: String?
    var rssi: NSNumber?
    var state: CBPeripheralState!
    var services: [CBServiceMock]?
    var canSendWriteWithoutResponse: Bool!
    var logDescription: String!
    var uuidIdentifier: UUID!
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
    var maximumWriteValueLengthReturn: Int?
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        maximumWriteValueLengthParams.append((type))
        if maximumWriteValueLengthReturns.isEmpty {
            return maximumWriteValueLengthReturn!
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
class CBDescriptorMock: NSObject {
    var characteristic: CBCharacteristicMock!
    var value: Any?
    var logDescription: String!
    var uuid: CBUUID!

    override init() {
    }

}
class CBServiceMock: NSObject {
    var peripheral: CBPeripheralMock!
    var isPrimary: Bool!
    var includedServices: [CBServiceMock]?
    var characteristics: [CBCharacteristicMock]?
    var logDescription: String!
    var uuid: CBUUID!

    override init() {
    }

}
class CBCharacteristicMock: NSObject {
    var service: CBServiceMock!
    var properties: CBCharacteristicProperties!
    var value: Data?
    var descriptors: [CBDescriptorMock]?
    var isBroadcasted: Bool!
    var isNotifying: Bool!
    var logDescription: String!
    var uuid: CBUUID!

    override init() {
    }

}
class CBL2CAPChannelMock: NSObject {
    var peer: CBPeerMock!
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var psm: CBL2CAPPSM!

    override init() {
    }

}
class CBPeerMock: NSObject {
    var identifier: UUID!

    override init() {
    }

}
class PeripheralDelegateWrapperProviderMock: NSObject {
    var lock: NSLock!
    var peripheralDelegateWrappersMap: [UUID: CBPeripheralDelegateWrapperMock]!

    override init() {
    }

    var provideParams: [(CBPeripheralMock)] = []
    var provideReturns: [CBPeripheralDelegateWrapperMock] = []
    var provideReturn: CBPeripheralDelegateWrapperMock?
    func provide(for peripheral: CBPeripheralMock) -> CBPeripheralDelegateWrapperMock {
        provideParams.append((peripheral))
        if provideReturns.isEmpty {
            return provideReturn!
        } else {
            return provideReturns.removeFirst()
        }
    }

}

// MARK: - generated wrapper mocks

class CBPeripheralDelegateWrapperMock: NSObject , CBPeripheralDelegate {
    var peripheralDidUpdateName = PublishSubject<String?>()
    var peripheralDidModifyServices = PublishSubject<([CBServiceMock])>()
    var peripheralDidReadRSSI = PublishSubject<(Int, Error?)>()
    var peripheralDidDiscoverServices = PublishSubject<([CBServiceMock]?, Error?)>()
    var peripheralDidDiscoverIncludedServicesForService = PublishSubject<(CBServiceMock, Error?)>()
    var peripheralDidDiscoverCharacteristicsForService = PublishSubject<(CBServiceMock, Error?)>()
    var peripheralDidUpdateValueForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    var peripheralDidWriteValueForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    var peripheralDidUpdateNotificationStateForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    var peripheralDidDiscoverDescriptorsForCharacteristic = PublishSubject<(CBCharacteristicMock, Error?)>()
    var peripheralDidUpdateValueForDescriptor = PublishSubject<(CBDescriptorMock, Error?)>()
    var peripheralDidWriteValueForDescriptor = PublishSubject<(CBDescriptorMock, Error?)>()
    var peripheralIsReadyToSendWriteWithoutResponse = PublishSubject<Void>()
    var peripheralDidOpenL2CAPChannel = PublishSubject<(Any?, Error?)>()

    override init() {
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI rssi: NSNumber, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    }

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
    }

}
class CBCentralManagerDelegateWrapperMock: NSObject , CBCentralManagerDelegate {
    var didUpdateState = PublishSubject<BluetoothState>()
    var willRestoreState = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    var didDiscoverPeripheral = PublishSubject<(CBPeripheralMock, [String: Any], NSNumber)>()
    var didConnectPeripheral = PublishSubject<CBPeripheralMock>()
    var didFailToConnectPeripheral = PublishSubject<(CBPeripheralMock, Error?)>()
    var didDisconnectPeripheral = PublishSubject<(CBPeripheralMock, Error?)>()

    override init() {
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }

}
