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
import RxTest
import RxSwift
import CoreBluetooth

class BluetoothManagerRetrievePeripheralsTest: XCTestCase {
    
    var manager: _BluetoothManager!
    
    var centralManagerMock: CBCentralManagerMock!
    var peripheralMock: CBPeripheralMock!
    var peripheralDelegateProviderMock: PeripheralDelegateWrapperProviderMock!
    var testScheduler: TestScheduler!
    
    // MARK:- retrievePeripherals
    
    func testViaIdentifiersBeforeSubscription() {
        _ = setUpViaIdentifiers()
        
        XCTAssertEqual(centralManagerMock.retrievePeripheralsParams.count, 0, "should not call retrieve method before subscription")
    }
    
    func testViaIdentifiersAfterSubscription() {
        let (uuids, peripheralsObserver) = setUpViaIdentifiers()
        
        testScheduler.advanceTo(TestScheduler.Defaults.subscribed)
        
        XCTAssertEqual(centralManagerMock.retrievePeripheralsParams.count, 1, "should call retrive method on central manager")
        XCTAssertEqual(centralManagerMock.retrievePeripheralsParams.first!, uuids, "should call it with proper identifiers")
        XCTAssertEqual(peripheralsObserver.events.count, 2, "should receive event in return")
        XCTAssertNotNil(peripheralsObserver.events.first?.value.element, "should retrieve next with peripherals table")
        XCTAssertEqual(peripheralsObserver.events.first!.value.element!.count, 1, "should retrieve next with exactly one peripheral in table")
        XCTAssertTrue(peripheralsObserver.events.first!.value.element!.first!.peripheral === peripheralMock, "should get proper peripheral")
    }
    
    func testViaIdentifiersErrorPropagationAtStart() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let (_, peripheralsObserver) = setUpViaIdentifiers()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            testScheduler.advanceTo(TestScheduler.Defaults.subscribed)
            
            XCTAssertGreaterThan(peripheralsObserver.events.count, 0, "should get error for state \(state)")
            XCTAssertError(peripheralsObserver.events.first!.value, error, "should get proper error \(error)")
        }
    }
    
    // MARK:- retrieveConnectedPeripherals
    
    func testViaServicesUuidsBeforeSubscription() {
        _ = setUpViaServicesUuids()
        
        XCTAssertEqual(centralManagerMock.retrieveConnectedPeripheralsParams.count, 0, "should not call retrieve method before subscription")
    }
    
    func testViaServicesUuidsAfterSubscription() {
        let (cbUuids, peripheralsObserver) = setUpViaServicesUuids()
        
        testScheduler.advanceTo(TestScheduler.Defaults.subscribed)
        
        XCTAssertEqual(centralManagerMock.retrieveConnectedPeripheralsParams.count, 1, "should call retrive method on central manager")
        XCTAssertEqual(centralManagerMock.retrieveConnectedPeripheralsParams.first!, cbUuids, "should call it with proper identifiers")
        XCTAssertEqual(peripheralsObserver.events.count, 2, "should receive event in return")
        XCTAssertNotNil(peripheralsObserver.events.first?.value.element, "should retrieve next with peripherals table")
        XCTAssertEqual(peripheralsObserver.events.first!.value.element!.count, 1, "should retrieve next with exactly one peripheral in table")
        XCTAssertTrue(peripheralsObserver.events.first!.value.element!.first!.peripheral === peripheralMock, "should get proper peripheral")
    }
    
    func testViaServicesUuidsErrorPropagationAtStart() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let (_, peripheralsObserver) = setUpViaServicesUuids()
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            testScheduler.advanceTo(TestScheduler.Defaults.subscribed)
            
            XCTAssertGreaterThan(peripheralsObserver.events.count, 0, "should get error for state \(state)")
            XCTAssertError(peripheralsObserver.events.first!.value, error, "should get proper error \(error)")
        }
    }
    
    // MARK: SetUp functions
    
    private func setUpViaIdentifiers() -> ([UUID], ScheduledObservable<[_Peripheral]>) {
        setUpProperties()
        
        let uuids = [UUID(), UUID()]
        let peripheralsObserver: ScheduledObservable<[_Peripheral]> = testScheduler.scheduleObservable {
            self.manager.retrievePeripherals(withIdentifiers: uuids).asObservable()
        }
        centralManagerMock.state = .poweredOn
        centralManagerMock.retrievePeripheralsReturns = [[peripheralMock]]
        peripheralDelegateProviderMock.provideReturns = [CBPeripheralDelegateWrapperMock()]
        return (uuids, peripheralsObserver)
    }
    
    private func setUpViaServicesUuids() -> ([CBUUID], ScheduledObservable<[_Peripheral]>) {
        setUpProperties()
        
        let cbUuids = [CBUUID()]
        let peripheralsObserver: ScheduledObservable<[_Peripheral]> = testScheduler.scheduleObservable {
            self.manager.retrieveConnectedPeripherals(withServices: cbUuids).asObservable()
        }
        centralManagerMock.state = .poweredOn
        centralManagerMock.retrieveConnectedPeripheralsReturns = [[peripheralMock]]
        peripheralDelegateProviderMock.provideReturns = [CBPeripheralDelegateWrapperMock()]
        return (cbUuids, peripheralsObserver)
    }
    
    private func setUpProperties() {
        peripheralMock = CBPeripheralMock()
        centralManagerMock = CBCentralManagerMock()
        peripheralDelegateProviderMock = PeripheralDelegateWrapperProviderMock()
        manager = _BluetoothManager(centralManager: centralManagerMock, delegateWrapper: CBCentralManagerDelegateWrapperMock(), peripheralDelegateProvider: peripheralDelegateProviderMock)
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
    }
}

