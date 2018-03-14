import XCTest
@testable
import RxBluetoothKit
import RxSwift
import RxTest

class CentralManagerTest_ObserveDisconnect: BaseCentralManagerTest {
    
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    func testBluetoothError() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let (peripheral, obs) = setUpObserveDisconnect()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(obs.events.count, 2, "should get event and error for state \(state)")
            XCTAssertTrue(obs.events[0].value.element!.0 === peripheral, "should get proper peripheral in next element")
            XCTAssertNotNil(obs.events[0].value.element!.1, "should get proper error in next element \(error)")
            XCTAssertTrue(obs.events[0].value.element!.1! is _BluetoothError, "should get proper error in next element \(error)")
            XCTAssertEqual(obs.events[0].value.element!.1! as! _BluetoothError, error, "should get proper error in next element \(error)")
            XCTAssertError(obs.events[1].value, error, "should get proper error \(error)")
        }
    }
    
    func testBluetoothErrorWithoutPeripheral() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let obs = setUpObserveDisconnectWithoutPeripheral()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            
            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(obs.events.count, 1, "should get error for state \(state)")
            XCTAssertError(obs.events[0].value, error, "should get proper error \(error)")
        }
    }
    
    func testObserveError() {
        let (_, obs) = setUpObserveDisconnect()
        testErrorEvent(with: obs)
    }
    
    func testObserveErrorWithoutPeripheral() {
        let obs = setUpObserveDisconnectWithoutPeripheral()
        testErrorEvent(with: obs)
    }

    func testDeviceDisconnectedEvent() {
        let (peripheral, obs) = setUpObserveDisconnect()
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime - 100, (peripheral.peripheral, nil)),
            next(subscribeTime + 100, (peripheral.peripheral, nil)),
            next(subscribeTime + 101, (peripheral.peripheral, _BluetoothError.bluetoothResetting)),
            next(subscribeTime + 102, (CBPeripheralMock(), nil)),
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn

        let expectedEvents: [Recorded<Event<(_Peripheral, DisconnectionReason?)>>] = [
            next(subscribeTime + 100, (peripheral, nil)),
            next(subscribeTime + 101, (peripheral, _BluetoothError.bluetoothResetting))
        ]
        
        testScheduler.advanceTo(subscribeTime + 200)

        testEvents(expectedEvents, obs)
    }
    
    func testDeviceDisconnectedEventWithoutPeripheral() {
        let peripheralMocks = [CBPeripheralMock(), CBPeripheralMock()]
        let obs = setUpObserveDisconnectWithoutPeripheral(peripheralMocks: peripheralMocks)
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime - 100, (CBPeripheralMock(), nil)),
            next(subscribeTime + 100, (peripheralMocks[0], nil)),
            next(subscribeTime + 101, (peripheralMocks[1], _BluetoothError.bluetoothResetting)),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive 2 disconnect events")
        XCTAssertEqual(obs.events[0].value.element!.0.peripheral, peripheralMocks[0], "should receive peripheral with correct CBPeripheral in 1 event")
        XCTAssertNil(obs.events[0].value.element!.1, "should receive nil error on 1 event")
        XCTAssertEqual(obs.events[1].value.element!.0.peripheral, peripheralMocks[1], "should receive peripheral with correct CBPeripheral in 2 event")
        XCTAssertEqual(obs.events[1].value.element!.1 as! _BluetoothError, _BluetoothError.bluetoothResetting, "should receive correct error for 2 event")
    }
    
    func testErrorAfterDeviceDisconnectedEvent() {
        let (peripheral, obs) = setUpObserveDisconnect()
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime + 100, (peripheral.peripheral, nil)),
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        let stateEvents: [Recorded<Event<BluetoothState>>] = [
            next(subscribeTime + 101, .unknown)
        ]
        testScheduler.createHotObservable(stateEvents).subscribe(wrapperMock.didUpdateState).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        let expectedEvents: [Recorded<Event<(_Peripheral, DisconnectionReason?)>>] = [
            next(subscribeTime + 100, (peripheral, nil)),
            next(subscribeTime + 101, (peripheral, _BluetoothError(state: .unknown)))
        ]
        let expectedError = _BluetoothError(state: .unknown)!
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 3, "should receive correct number of events")
        testEvents(expectedEvents, obs)
        XCTAssertError(obs.events[2].value, expectedError, "should receive correct error event as last event")
    }
    
    func testErrorAfterDeviceDisconnectedEventWithoutPeripheral() {
        let peripheralMock = CBPeripheralMock()
        let obs = setUpObserveDisconnectWithoutPeripheral(peripheralMocks: [peripheralMock])
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime + 100, (peripheralMock, nil)),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        let stateEvents: [Recorded<Event<BluetoothState>>] = [
            next(subscribeTime + 101, .unknown)
        ]
        testScheduler.createHotObservable(stateEvents).subscribe(wrapperMock.didUpdateState).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive disconnect and error event")
        XCTAssertEqual(obs.events[0].value.element!.0.peripheral, peripheralMock, "should receive peripheral with correct CBPeripheral in disconnect event")
        XCTAssertNil(obs.events[0].value.element!.1, "should receive nil error on disconnect event")
        XCTAssertError(obs.events[1].value, _BluetoothError(state: .unknown)!, "should receive correct error")
    }
    
    // MARK: - Utils
    
    private func testErrorEvent(with obs: ScheduledObservable<(_Peripheral, DisconnectionReason?)>) {
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            error(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDisconnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should get only one error event")
        XCTAssertNotNil(obs.events[0].value.error, "should get error")
    }
    
    private func testEvents(_ expectedEvents: [Recorded<Event<(_Peripheral, DisconnectionReason?)>>], _ peripheralsObserver: ScheduledObservable<(_Peripheral, DisconnectionReason?)>) {
        for eventIndex in 0...(expectedEvents.count - 2) {
            let element = peripheralsObserver.events[eventIndex].value.element!
            let expected = expectedEvents[eventIndex].value.element!
            XCTAssertEqual(element.0, expected.0, "should receive same peripheral for event index \(eventIndex)")
            if expected.1 == nil {
                XCTAssertNil(element.1, "should receive nil error for event index \(eventIndex)")
            } else {
                XCTAssertEqual(element.1! as! _BluetoothError, expected.1! as! _BluetoothError, "should receive correct error for event index \(eventIndex)")
            }
        }
    }
    
    private func setUpObserveDisconnect() -> (_Peripheral, ScheduledObservable<(_Peripheral, DisconnectionReason?)>) {
        setUpProperties()
        
        let peripheral = _Peripheral(manager: manager, peripheral: CBPeripheralMock(), delegateWrapper: CBPeripheralDelegateWrapperMock())
        providerMock.provideReturn = peripheral
        let disconnectObserver: ScheduledObservable<(_Peripheral, DisconnectionReason?)> = testScheduler.scheduleObservable {
            self.manager.observeDisconnect(for: peripheral).asObservable()
        }
        return (peripheral, disconnectObserver)
    }
    
    private func setUpObserveDisconnectWithoutPeripheral(peripheralMocks: [CBPeripheralMock] = []) -> ScheduledObservable<(_Peripheral, DisconnectionReason?)> {
        setUpProperties()
        
        let peripherals = peripheralMocks.map { _Peripheral(manager: manager, peripheral: $0, delegateWrapper: CBPeripheralDelegateWrapperMock()) }
        providerMock.provideReturns = peripherals
        let disconnectObserver: ScheduledObservable<(_Peripheral, DisconnectionReason?)> = testScheduler.scheduleObservable {
            self.manager.observeDisconnect().asObservable()
        }
        return disconnectObserver
    }
    
    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
