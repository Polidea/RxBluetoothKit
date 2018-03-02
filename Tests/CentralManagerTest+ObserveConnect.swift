import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

class CentralManagerTest_ObserveConnect: BaseCentralManagerTest {
    
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    func testBluetoothError() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let (_, obs) = setUpObserveConnect()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            
            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(obs.events.count, 1, "should get error for state \(state)")
            XCTAssertError(obs.events[0].value, error, "should get proper error \(error)")
        }
    }
    
    func testBluetoothErrorWithoutPeripheral() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let obs = setUpObserveConnectWithoutPeripheral()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            
            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(obs.events.count, 1, "should get error for state \(state)")
            XCTAssertError(obs.events[0].value, error, "should get proper error \(error)")
        }
    }
    
    func testObserveError() {
        let (_, obs) = setUpObserveConnect()
        testErrorEvent(with: obs)
    }
    
    func testObserveErrorWithoutPeripheral() {
        let obs = setUpObserveConnectWithoutPeripheral()
        testErrorEvent(with: obs)
    }
    
    func testDeviceConnectedEvent() {
        let (peripheral, obs) = setUpObserveConnect()
        let events: [Recorded<Event<CBPeripheralMock>>] = [
            next(subscribeTime - 100, peripheral.peripheral),
            next(subscribeTime + 100, peripheral.peripheral),
            next(subscribeTime + 102, CBPeripheralMock()),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should receive only one connected event")
        XCTAssertEqual(obs.events[0].value.element!, peripheral, "should receive correct peripheral object")
    }
    
    func testDeviceConnectedEventWithoutPeripheral() {
        let peripheralMocks = [CBPeripheralMock(), CBPeripheralMock()]
        let obs = setUpObserveConnectWithoutPeripheral(peripheralMocks: peripheralMocks)
        let events: [Recorded<Event<CBPeripheralMock>>] = [
            next(subscribeTime - 100, CBPeripheralMock()),
            next(subscribeTime + 100, peripheralMocks[0]),
            next(subscribeTime + 102, peripheralMocks[1]),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two connected event")
        XCTAssertEqual(obs.events[0].value.element!.peripheral, peripheralMocks[0], "should receive peripheral with correct CBPeripheral on 1 event")
        XCTAssertEqual(obs.events[1].value.element!.peripheral, peripheralMocks[1], "should receive peripheral with correct CBPeripheral on 2 event")
    }
    
    func testErrorAfterConnectedEvent() {
        let (peripheral, obs) = setUpObserveConnect()
        let events: [Recorded<Event<CBPeripheralMock>>] = [
            next(subscribeTime + 100, peripheral.peripheral),
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        let stateEvents: [Recorded<Event<BluetoothState>>] = [
            next(subscribeTime + 101, .unknown)
        ]
        testScheduler.createHotObservable(stateEvents).subscribe(wrapperMock.didUpdateState).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive connected and error events")
        XCTAssertEqual(obs.events[0].value.element!, peripheral, "should receive correct peripheral object in connected event")
        XCTAssertError(obs.events[1].value, _BluetoothError.bluetoothInUnknownState, "should receive correct error event")
    }
    
    func testErrorAfterConnectedEventWithoutPeripheral() {
        let peripheralMock = CBPeripheralMock()
        let obs = setUpObserveConnectWithoutPeripheral(peripheralMocks: [peripheralMock])
        let events: [Recorded<Event<CBPeripheralMock>>] = [
            next(subscribeTime + 100, peripheralMock),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        let stateEvents: [Recorded<Event<BluetoothState>>] = [
            next(subscribeTime + 101, .unknown)
        ]
        testScheduler.createHotObservable(stateEvents).subscribe(wrapperMock.didUpdateState).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive connected and error events")
        XCTAssertEqual(obs.events[0].value.element!.peripheral, peripheralMock, "should receive correct peripheral object in connected event")
        XCTAssertError(obs.events[1].value, _BluetoothError.bluetoothInUnknownState, "should receive correct error event")
    }
    
    // Mark: - Utilities
    
    private func testErrorEvent(with obs: ScheduledObservable<_Peripheral>) {
        let events: [Recorded<Event<CBPeripheralMock>>] = [
            error(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didConnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should get only one error event")
        XCTAssertNotNil(obs.events[0].value.error, "should get error")
    }
    
    func setUpObserveConnect() -> (_Peripheral, ScheduledObservable<_Peripheral>) {
        setUpProperties()
        
        let peripheral = _Peripheral(manager: manager, peripheral: CBPeripheralMock(), delegateWrapper: CBPeripheralDelegateWrapperMock())
        providerMock.provideReturn = peripheral
        let connectObservable: ScheduledObservable<_Peripheral> = testScheduler.scheduleObservable {
            self.manager.observeConnect(for: peripheral).asObservable()
        }
        return (peripheral, connectObservable)
    }
    
    func setUpObserveConnectWithoutPeripheral(peripheralMocks: [CBPeripheralMock] = []) -> ScheduledObservable<_Peripheral> {
        setUpProperties()
        
        let peripherals = peripheralMocks.map { _Peripheral(manager: manager, peripheral: $0, delegateWrapper: CBPeripheralDelegateWrapperMock()) }
        providerMock.provideReturns = peripherals
        let connectObservable: ScheduledObservable<_Peripheral> = testScheduler.scheduleObservable {
            self.manager.observeConnect().asObservable()
        }
        return connectObservable
    }
    
    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
