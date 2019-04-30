// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import CoreBluetooth
@testable
import RxBluetoothKit
import RxSwift

// MARK: - generated class mocks

class CBManagerMock: NSObject {
    var state: CBManagerState!

    override init() {
    }

}
class CBAttributeMock: NSObject {
    var uuid: CBUUID!

    override init() {
    }

}
class CBCentralManagerMock: CBManagerMock {
    var delegate: CBCentralManagerDelegate?
    var isScanning: Bool!
    var logDescription: String!

    override init() {
    }
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
    }
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?) {
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
class CBPeripheralManagerMock: CBManagerMock {
    var delegate: CBPeripheralManagerDelegate?
    var isAdvertising: Bool!
    var logDescription: String!

    override init() {
    }
    init(delegate: CBPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
    }
    init(delegate: CBPeripheralManagerDelegate?, queue: DispatchQueue?) {
    }

    static var authorizationStatusParams: [()] = []
    static var authorizationStatusReturns: [CBPeripheralManagerAuthorizationStatus] = []
    static var authorizationStatusReturn: CBPeripheralManagerAuthorizationStatus?
    static func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus {
        authorizationStatusParams.append(())
        if authorizationStatusReturns.isEmpty {
            return authorizationStatusReturn!
        } else {
            return authorizationStatusReturns.removeFirst()
        }
    }

    var startAdvertisingParams: [([String : Any]?)] = []
    func startAdvertising(_ advertisementData: [String : Any]?) {
        startAdvertisingParams.append((advertisementData))
    }

    var stopAdvertisingParams: [()] = []
    func stopAdvertising() {
        stopAdvertisingParams.append(())
    }

    var setDesiredConnectionLatencyParams: [(CBPeripheralManagerConnectionLatency, CBCentralMock)] = []
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentralMock) {
        setDesiredConnectionLatencyParams.append((latency, central))
    }

    var addParams: [(CBMutableService)] = []
    func add(_ service: CBMutableService) {
        addParams.append((service))
    }

    var removeParams: [(CBMutableService)] = []
    func remove(_ service: CBMutableService) {
        removeParams.append((service))
    }

    var removeAllServicesParams: [()] = []
    func removeAllServices() {
        removeAllServicesParams.append(())
    }

    var respondParams: [(CBATTRequestMock, CBATTError.Code)] = []
    func respond(to request: CBATTRequestMock, withResult result: CBATTError.Code) {
        respondParams.append((request, result))
    }

    var updateValueParams: [(Data, CBMutableCharacteristic, [CBCentralMock]?)] = []
    var updateValueReturns: [Bool] = []
    var updateValueReturn: Bool?
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentralMock]?) -> Bool {
        updateValueParams.append((value, characteristic, centrals))
        if updateValueReturns.isEmpty {
            return updateValueReturn!
        } else {
            return updateValueReturns.removeFirst()
        }
    }

    var publishL2CAPChannelParams: [(Bool)] = []
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {
        publishL2CAPChannelParams.append((encryptionRequired))
    }

    var unpublishL2CAPChannelParams: [(CBL2CAPPSM)] = []
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {
        unpublishL2CAPChannelParams.append((PSM))
    }

}
class CBPeripheralMock: CBPeerMock {
    var delegate: CBPeripheralDelegate?
    var name: String?
    var rssi: NSNumber?
    var state: CBPeripheralState!
    var services: [CBServiceMock]?
    var canSendWriteWithoutResponse: Bool!
    var logDescription: String!
    var uuidIdentifier: UUID!

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
class CBDescriptorMock: CBAttributeMock {
    var characteristic: CBCharacteristicMock!
    var value: Any?
    var logDescription: String!

    override init() {
    }

}
class CBServiceMock: CBAttributeMock {
    var peripheral: CBPeripheralMock!
    var isPrimary: Bool!
    var includedServices: [CBServiceMock]?
    var characteristics: [CBCharacteristicMock]?
    var logDescription: String!

    override init() {
    }

}
class CBCharacteristicMock: CBAttributeMock {
    var service: CBServiceMock!
    var properties: CBCharacteristicProperties!
    var value: Data?
    var descriptors: [CBDescriptorMock]?
    var isBroadcasted: Bool!
    var isNotifying: Bool!
    var logDescription: String!

    override init() {
    }

}
class CBL2CAPChannelMock: NSObject {
    var peer: CBPeerMock!
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var psm: CBL2CAPPSM!
    var logDescription: String!

    override init() {
    }

}
class CBPeerMock: NSObject {
    var identifier: UUID!

    override init() {
    }

}
class CBATTRequestMock: NSObject {
    var central: CBCentralMock!
    var characteristic: CBCharacteristicMock!
    var offset: Int!
    var value: Data?
    var logDescription: String!

    override init() {
    }

}
class CBCentralMock: CBPeerMock {
    var maximumUpdateValueLength: Int!
    var logDescription: String!
    var uuidIdentifier: UUID!

    override init() {
    }

}
class PeripheralProviderMock: NSObject {
    var peripheralsBox: ThreadSafeBox<[_Peripheral]>!
    var delegateWrappersBox: ThreadSafeBox<[UUID: CBPeripheralDelegateWrapperMock]>!

    override init() {
    }

    var provideDelegateWrapperParams: [(CBPeripheralMock)] = []
    var provideDelegateWrapperReturns: [CBPeripheralDelegateWrapperMock] = []
    var provideDelegateWrapperReturn: CBPeripheralDelegateWrapperMock?
    func provideDelegateWrapper(for peripheral: CBPeripheralMock) -> CBPeripheralDelegateWrapperMock {
        provideDelegateWrapperParams.append((peripheral))
        if provideDelegateWrapperReturns.isEmpty {
            return provideDelegateWrapperReturn!
        } else {
            return provideDelegateWrapperReturns.removeFirst()
        }
    }

    var provideParams: [(CBPeripheralMock, _CentralManager)] = []
    var provideReturns: [_Peripheral] = []
    var provideReturn: _Peripheral?
    func provide(for cbPeripheral: CBPeripheralMock, centralManager: _CentralManager) -> _Peripheral {
        provideParams.append((cbPeripheral, centralManager))
        if provideReturns.isEmpty {
            return provideReturn!
        } else {
            return provideReturns.removeFirst()
        }
    }

    var createAndAddToBoxParams: [(CBPeripheralMock, _CentralManager)] = []
    var createAndAddToBoxReturns: [_Peripheral] = []
    var createAndAddToBoxReturn: _Peripheral?
    func createAndAddToBox(_ cbPeripheral: CBPeripheralMock, manager: _CentralManager) -> _Peripheral {
        createAndAddToBoxParams.append((cbPeripheral, manager))
        if createAndAddToBoxReturns.isEmpty {
            return createAndAddToBoxReturn!
        } else {
            return createAndAddToBoxReturns.removeFirst()
        }
    }

    var findParams: [(CBPeripheralMock)] = []
    var findReturns: [_Peripheral?] = []
    var findReturn: _Peripheral??
    func find(_ cbPeripheral: CBPeripheralMock) -> _Peripheral? {
        findParams.append((cbPeripheral))
        if findReturns.isEmpty {
            return findReturn!
        } else {
            return findReturns.removeFirst()
        }
    }

}
class ConnectorMock: NSObject {
    var centralManager: CBCentralManagerMock!
    var delegateWrapper: CBCentralManagerDelegateWrapperMock!
    var connectedBox: ThreadSafeBox<Set<UUID>>!
    var disconnectingBox: ThreadSafeBox<Set<UUID>>!

    override init() {
    }
    init(centralManager: CBCentralManagerMock, delegateWrapper: CBCentralManagerDelegateWrapperMock) {
    }

    var establishConnectionParams: [(_Peripheral, [String: Any]?)] = []
    var establishConnectionReturns: [Observable<_Peripheral>] = []
    var establishConnectionReturn: Observable<_Peripheral>?
    func establishConnection(with peripheral: _Peripheral, options: [String: Any]? = nil) -> Observable<_Peripheral> {
        establishConnectionParams.append((peripheral, options))
        if establishConnectionReturns.isEmpty {
            return establishConnectionReturn!
        } else {
            return establishConnectionReturns.removeFirst()
        }
    }

    var createConnectionObservableParams: [(_Peripheral, [String: Any]?)] = []
    var createConnectionObservableReturns: [Observable<_Peripheral>] = []
    var createConnectionObservableReturn: Observable<_Peripheral>?
    func createConnectionObservable(for peripheral: _Peripheral, options: [String: Any]? = nil) -> Observable<_Peripheral> {
        createConnectionObservableParams.append((peripheral, options))
        if createConnectionObservableReturns.isEmpty {
            return createConnectionObservableReturn!
        } else {
            return createConnectionObservableReturns.removeFirst()
        }
    }

    var createConnectedObservableParams: [(_Peripheral)] = []
    var createConnectedObservableReturns: [Observable<_Peripheral>] = []
    var createConnectedObservableReturn: Observable<_Peripheral>?
    func createConnectedObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        createConnectedObservableParams.append((peripheral))
        if createConnectedObservableReturns.isEmpty {
            return createConnectedObservableReturn!
        } else {
            return createConnectedObservableReturns.removeFirst()
        }
    }

    var createDisconnectedObservableParams: [(_Peripheral)] = []
    var createDisconnectedObservableReturns: [Observable<_Peripheral>] = []
    var createDisconnectedObservableReturn: Observable<_Peripheral>?
    func createDisconnectedObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        createDisconnectedObservableParams.append((peripheral))
        if createDisconnectedObservableReturns.isEmpty {
            return createDisconnectedObservableReturn!
        } else {
            return createDisconnectedObservableReturns.removeFirst()
        }
    }

    var createFailToConnectObservableParams: [(_Peripheral)] = []
    var createFailToConnectObservableReturns: [Observable<_Peripheral>] = []
    var createFailToConnectObservableReturn: Observable<_Peripheral>?
    func createFailToConnectObservable(for peripheral: _Peripheral) -> Observable<_Peripheral> {
        createFailToConnectObservableParams.append((peripheral))
        if createFailToConnectObservableReturns.isEmpty {
            return createFailToConnectObservableReturn!
        } else {
            return createFailToConnectObservableReturns.removeFirst()
        }
    }

}
class CharacteristicNotificationManagerMock: NSObject {
    var peripheral: CBPeripheralMock!
    var delegateWrapper: CBPeripheralDelegateWrapperMock!
    var uuidToActiveObservableMap: [CBUUID: Observable<_Characteristic>]!
    var uuidToActiveObservablesCountMap: [CBUUID: Int]!
    var lock: NSLock!

    override init() {
    }
    init(peripheral: CBPeripheralMock, delegateWrapper: CBPeripheralDelegateWrapperMock) {
    }

    var observeValueUpdateAndSetNotificationParams: [(_Characteristic)] = []
    var observeValueUpdateAndSetNotificationReturns: [Observable<_Characteristic>] = []
    var observeValueUpdateAndSetNotificationReturn: Observable<_Characteristic>?
    func observeValueUpdateAndSetNotification(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        observeValueUpdateAndSetNotificationParams.append((characteristic))
        if observeValueUpdateAndSetNotificationReturns.isEmpty {
            return observeValueUpdateAndSetNotificationReturn!
        } else {
            return observeValueUpdateAndSetNotificationReturns.removeFirst()
        }
    }

    var createValueUpdateObservableParams: [(_Characteristic)] = []
    var createValueUpdateObservableReturns: [Observable<_Characteristic>] = []
    var createValueUpdateObservableReturn: Observable<_Characteristic>?
    func createValueUpdateObservable(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        createValueUpdateObservableParams.append((characteristic))
        if createValueUpdateObservableReturns.isEmpty {
            return createValueUpdateObservableReturn!
        } else {
            return createValueUpdateObservableReturns.removeFirst()
        }
    }

    var setNotifyValueParams: [(Bool, _Characteristic)] = []
    func setNotifyValue(_ enabled: Bool, for characteristic: _Characteristic) {
        setNotifyValueParams.append((enabled, characteristic))
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
class CBPeripheralManagerDelegateWrapperMock: NSObject , CBPeripheralManagerDelegate {
    var didUpdateState = PublishSubject<BluetoothState>()
    var isReady = PublishSubject<Void>()
    var didStartAdvertising = PublishSubject<Error?>()
    var didReceiveRead = PublishSubject<CBATTRequestMock>()
    var willRestoreState = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    var didAddService = PublishSubject<(CBServiceMock, Error?)>()
    var didReceiveWrite = PublishSubject<[CBATTRequestMock]>()
    var didSubscribeTo = PublishSubject<(CBCentralMock, CBCharacteristicMock)>()
    var didUnsubscribeFrom = PublishSubject<(CBCentralMock, CBCharacteristicMock)>()
    var didPublishL2CAPChannel = PublishSubject<(CBL2CAPPSM, Error?)>()
    var didUnpublishL2CAPChannel = PublishSubject<(CBL2CAPPSM, Error?)>()
    var _didOpenChannel: Any?
    var didOpenChannel: PublishSubject<(CBL2CAPChannelMock?, Error?)>!

    override init() {
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
    }

}
