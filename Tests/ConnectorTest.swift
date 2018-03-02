import Foundation
import XCTest
import RxTest
import RxSwift
@testable
import RxBluetoothKit

class ConnectorTest: XCTestCase {
    var connector: _Connector!
    
    var peripheralMock: CBPeripheralMock!
    var centralManagerMock: CBCentralManagerMock!
    var wrapperMock: CBCentralManagerDelegateWrapperMock!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    let disposeTime = TestScheduler.Defaults.disposed
    
    func testConnectedPeripheral() {
        let (peripheral, obs) = setUpObserver(options: nil)
        peripheralMock.uuidIdentifier = UUID()
        peripheralMock.state = .connected
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(obs.events.count, 1, "should receive error event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralIsConnectingOrAlreadyConnected(peripheral), "should receive correct error event")
    }
    
    func testAlreadyConnectingPeripheral() {
        let uuid = UUID()
        let (peripheral, obs) = setUpObserver(options: nil, connectingUuids: [uuid])
        peripheralMock.uuidIdentifier = uuid
        peripheralMock.state = .disconnected
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(obs.events.count, 1, "should receive error event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralIsConnectingOrAlreadyConnected(peripheral), "should receive correct error event")
    }
    
    func testDisconnectingPeripheral() {
        let uuid = UUID()
        let (_, obs) = setUpObserver(options: nil, disconnectingUuids: [uuid])
        let disconnectEvent: Recorded<Event<(CBPeripheralMock, Error?)>> = next(subscribeTime + 100, (peripheralMock, TestError.error))
        testScheduler.createHotObservable([disconnectEvent]).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        peripheralMock.uuidIdentifier = uuid
        peripheralMock.state = .disconnecting
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(obs.events.count, 0, "should not receive anyevent when disconnecting")
        XCTAssertFalse(connector.connectingBox.read({ $0.contains(uuid) }), "should not set peripheral as connecting")
        XCTAssertTrue(connector.disconnectingBox.read({ $0.contains(uuid) }), "should still have peripheral as disconnecting set")
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertTrue(connector.connectingBox.read({ $0.contains(uuid) }), "should set peripheral as connecting")
        XCTAssertFalse(connector.disconnectingBox.read({ $0.contains(uuid) }), "should unset peripheral as disconnecting")
        XCTAssertEqual(centralManagerMock.connectParams.count, 1, "should call connect")
    }
    
    func testProperConnectCall() {
        let (_, _) = setUpObserver(options: ["key": "value"])
        peripheralMock.uuidIdentifier = UUID()
        peripheralMock.state = .disconnected
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(centralManagerMock.connectParams.count, 1, "should call connect method")
        XCTAssertEqual(centralManagerMock.connectParams[0].0, peripheralMock, "should call connect with proper params")
        XCTAssertNotNil((centralManagerMock.connectParams[0].1!)["key"], "should call connect with proper params")
        XCTAssertEqual((centralManagerMock.connectParams[0].1!)["key"] as! String, "value", "should call connect with proper params")
    }
    
    func testStateChangedToConnecting() {
        let (_, _, uuid) = setUpConnectableObserver()
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertTrue(connector.connectingBox.read({ $0.contains(uuid) }), "should add peripheral uuid to connecting state")
    }
    
    func testConnectedEvent() {
        let (peripheral, obs, _) = setUpConnectableObserver()
        let connectEvent: Recorded<Event<CBPeripheralMock>> = next(subscribeTime + 100, peripheralMock)
        let failEvent: Recorded<Event<(CBPeripheralMock, Error?)>> = next(subscribeTime + 101, (peripheralMock, nil))
        testScheduler.createHotObservable([connectEvent]).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        testScheduler.createHotObservable([failEvent]).subscribe(wrapperMock.didFailToConnectPeripheral).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should get connected event")
        XCTAssertEqual(obs.events[0].value.element!, peripheral, "should get proper event element")
    }
    
    func testConnectFailEvent() {
        let (peripheral, obs, _) = setUpConnectableObserver()
        let connectEvent: Recorded<Event<CBPeripheralMock>> = next(subscribeTime + 100, peripheralMock)
        let failEvent: Recorded<Event<(CBPeripheralMock, Error?)>> = next(subscribeTime + 99, (peripheralMock, TestError.error))
        testScheduler.createHotObservable([connectEvent]).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        testScheduler.createHotObservable([failEvent]).subscribe(wrapperMock.didFailToConnectPeripheral).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should get error event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralConnectionFailed(peripheral, TestError.error), "should get proper error event")
    }
    
    func testDisconnectedEvent() {
        let (peripheral, obs, _) = setUpConnectableObserver()
        let connectEvent: Recorded<Event<CBPeripheralMock>> = next(subscribeTime + 100, peripheralMock)
        let disconnectEvent: Recorded<Event<(CBPeripheralMock, Error?)>> = next(subscribeTime + 200, (peripheralMock, TestError.error))
        testScheduler.createHotObservable([connectEvent]).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        testScheduler.createHotObservable([disconnectEvent]).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 300)
        
        XCTAssertEqual(obs.events.count, 2, "should get connect and disconnect event")
        XCTAssertEqual(obs.events[0].value.element!, peripheral, "should get proper connect event element")
        XCTAssertError(obs.events[1].value, _BluetoothError.peripheralDisconnected(peripheral, TestError.error), "should get proper disconnect event element")
    }
    
    func testCancellingConnectionWhenConnectedOnDispose() {
        let (_, _, uuid) = setUpConnectableObserver()
        
        testScheduler.advanceTo(subscribeTime)
        connector.connectingBox.write { $0.remove(uuid) }
        peripheralMock.state = .connected
        testScheduler.advanceTo(disposeTime)
        
        XCTAssertEqual(centralManagerMock.cancelPeripheralConnectionParams.count, 1, "should call cancel peripheral connection method")
        XCTAssertEqual(centralManagerMock.cancelPeripheralConnectionParams[0], peripheralMock, "should call cancel peripheral connection with proper params")
    }
    
    func testCancellingConnectionWhenConnectingOnDispose() {
        let (_, _, uuid) = setUpConnectableObserver()
        
        testScheduler.advanceTo(subscribeTime)
        connector.connectingBox.write { $0.insert(uuid) }
        peripheralMock.state = .disconnected
        testScheduler.advanceTo(disposeTime)
        
        XCTAssertEqual(centralManagerMock.cancelPeripheralConnectionParams.count, 1, "should call cancel peripheral connection method")
        XCTAssertEqual(centralManagerMock.cancelPeripheralConnectionParams[0], peripheralMock, "should call cancel peripheral connection with proper params")
    }
    
    func testNotCancellingConnectioOnDispose() {
        let (_, _, uuid) = setUpConnectableObserver()
        
        testScheduler.advanceTo(subscribeTime)
        connector.connectingBox.write { $0.remove(uuid) }
        peripheralMock.state = .disconnected
        testScheduler.advanceTo(disposeTime)
        
        XCTAssertEqual(centralManagerMock.cancelPeripheralConnectionParams.count, 0, "should not call cancel peripheral connection method")
    }
    
    // Mark: - Utilities
    
    func setUpConnectableObserver() -> (_Peripheral, ScheduledObservable<_Peripheral>, UUID) {
        let uuid = UUID()
        let (peripheral, obs) = setUpObserver()
        peripheralMock.uuidIdentifier = uuid
        peripheralMock.state = .disconnected
        return (peripheral, obs, uuid)
    }
    
    func setUpObserver(options: [String: Any]? = nil, connectingUuids: [UUID] = [], disconnectingUuids: [UUID] = [])
        -> (_Peripheral, ScheduledObservable<_Peripheral>) {
        setUpProperties(connectingUuids: connectingUuids, disconnectingUuids: disconnectingUuids)
        
        let peripheralProvider = PeripheralProviderMock()
        let centralManager = _CentralManager(centralManager: centralManagerMock, delegateWrapper: wrapperMock, peripheralProvider: peripheralProvider, connector: ConnectorMock())
        let peripheral = _Peripheral(manager: centralManager, peripheral: peripheralMock, delegateWrapper: CBPeripheralDelegateWrapperMock())
        peripheralProvider.provideReturn = peripheral
        let observable: ScheduledObservable<_Peripheral> = testScheduler.scheduleObservable {
            self.connector.establishConnection(with: peripheral, options: options)
        }
        return (peripheral, observable)
    }
    
    func setUpProperties(connectingUuids: [UUID] = [], disconnectingUuids: [UUID] = []) {
        peripheralMock = CBPeripheralMock()
        centralManagerMock = CBCentralManagerMock()
        wrapperMock = CBCentralManagerDelegateWrapperMock()
        connector = _Connector(
            centralManager: centralManagerMock,
            delegateWrapper: wrapperMock
        )
        connector.connectingBox.write { $0.formUnion(connectingUuids) }
        connector.disconnectingBox.write { $0.formUnion(disconnectingUuids) }
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
