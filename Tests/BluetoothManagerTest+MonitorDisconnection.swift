// The MIT License (MIT)
//
// Copyright (c) 2018 Polidea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
@testable
import RxBluetoothKit
import RxSwift
import RxTest

class BluetoothManagerTest_MonitorDisconnection: XCTestCase {
    
    var manager: _BluetoothManager!
    
    var centralManagerMock: CBCentralManagerMock!
    var delegateWrapper: CBCentralManagerDelegateWrapperMock!
    var peripheralDelegateProviderMock: PeripheralDelegateWrapperProviderMock!
    var testScheduler: TestScheduler!
    
    let subscribeTime = TestScheduler.Defaults.subscribed
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }
    
    func testBluetoothError() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let (peripheral, peripheralsObserver) = setUpMonitorDisconnection()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(peripheralsObserver.events.count, 2, "should get event and error for state \(state)")
            XCTAssertTrue(peripheralsObserver.events[0].value.element!.0 === peripheral, "should get proper peripheral in next element")
            XCTAssertNotNil(peripheralsObserver.events[0].value.element!.1, "should get proper error in next element \(error)")
            XCTAssertTrue(peripheralsObserver.events[0].value.element!.1! is _BluetoothError, "should get proper error in next element \(error)")
            XCTAssertEqual(peripheralsObserver.events[0].value.element!.1! as! _BluetoothError, error, "should get proper error in next element \(error)")
            XCTAssertError(peripheralsObserver.events[1].value, error, "should get proper error \(error)")
        }
    }
    
    func testMonitorError() {
        let (_, peripheralsObserver) = setUpMonitorDisconnection()
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            error(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(delegateWrapper.didDisconnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(peripheralsObserver.events.count, 1, "should get only one error event")
        XCTAssertNotNil(peripheralsObserver.events[0].value.error, "should get error")
    }

    func testDeviceDisconnectedEvent() {
        let (peripheral, peripheralsObserver) = setUpMonitorDisconnection()
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime - 100, (peripheral.peripheral, nil)),
            next(subscribeTime + 100, (peripheral.peripheral, nil)),
            next(subscribeTime + 101, (peripheral.peripheral, _BluetoothError.bluetoothResetting)),
            next(subscribeTime + 102, (CBPeripheralMock(), nil)),
        ]
        testScheduler.createHotObservable(events).subscribe(delegateWrapper.didDisconnectPeripheral).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn

        let expectedEvents: [Recorded<Event<(_Peripheral, _BluetoothManager.DisconnectionReason?)>>] = [
            next(subscribeTime + 100, (peripheral, nil)),
            next(subscribeTime + 101, (peripheral, _BluetoothError.bluetoothResetting))
        ]
        
        testScheduler.advanceTo(subscribeTime + 200)

        testEvents(expectedEvents, peripheralsObserver)
    }
    
    func testErrorAfterDeviceDisconnectedEvent() {
        let (peripheral, peripheralsObserver) = setUpMonitorDisconnection()
        let events: [Recorded<Event<(CBPeripheralMock, Error?)>>] = [
            next(subscribeTime + 100, (peripheral.peripheral, nil)),
        ]
        testScheduler.createHotObservable(events).subscribe(delegateWrapper.didDisconnectPeripheral).disposed(by: disposeBag)
        let stateEvents: [Recorded<Event<BluetoothState>>] = [
            next(subscribeTime + 101, .unknown)
        ]
        testScheduler.createHotObservable(stateEvents).subscribe(delegateWrapper.didUpdateState).disposed(by: disposeBag)
        centralManagerMock.state = .poweredOn
        
        let expectedEvents: [Recorded<Event<(_Peripheral, _BluetoothManager.DisconnectionReason?)>>] = [
            next(subscribeTime + 100, (peripheral, nil)),
            next(subscribeTime + 101, (peripheral, _BluetoothError(state: .unknown)))
        ]
        let expectedError = _BluetoothError(state: .unknown)!
        
        testScheduler.advanceTo(subscribeTime + 200)
        centralManagerMock.state = .unknown
        
        testEvents(expectedEvents, peripheralsObserver)
        XCTAssertError(peripheralsObserver.events[2].value, expectedError, "should receive correct error event as last event")
    }
    
    // MARK: - Utils
    
    private func testEvents(_ expectedEvents: [Recorded<Event<(_Peripheral, _BluetoothManager.DisconnectionReason?)>>], _ peripheralsObserver: ScheduledObservable<(_Peripheral, _BluetoothManager.DisconnectionReason?)>) {
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
    
    private func setUpMonitorDisconnection() -> (_Peripheral, ScheduledObservable<(_Peripheral, _BluetoothManager.DisconnectionReason?)>) {
        setUpProperties()
        
        peripheralDelegateProviderMock.provideReturns = [CBPeripheralDelegateWrapperMock()]
        let peripheral = _Peripheral(manager: manager, peripheral: CBPeripheralMock())
        let peripheralsObserver: ScheduledObservable<(_Peripheral, _BluetoothManager.DisconnectionReason?)> = testScheduler.scheduleObservable {
            self.manager.monitorDisconnection(for: peripheral).asObservable()
        }
        return (peripheral, peripheralsObserver)
    }
    
    private func setUpProperties() {
        centralManagerMock = CBCentralManagerMock()
        delegateWrapper = CBCentralManagerDelegateWrapperMock()
        peripheralDelegateProviderMock = PeripheralDelegateWrapperProviderMock()
        manager = _BluetoothManager(centralManager: centralManagerMock, delegateWrapper: delegateWrapper, peripheralDelegateProvider: peripheralDelegateProviderMock)
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
    }
}
