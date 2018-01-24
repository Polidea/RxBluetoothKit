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
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

class BluetoothManagerTest_ScanForPeripherals: BaseBluetoothManagerTest {
    
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed

    func testErrorPropagationAtStart() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let observer = setUpScanForPeripherals(withServices: nil, options: nil)
            let (state, error) = stateWithError
            
            centralManagerMock.state = state
            
            testScheduler.advanceTo(subscribeTime)
            
            XCTAssertEqual(observer.events.count, 1, "should get error for state \(state)")
            XCTAssertError(observer.events[0].value, error, "should get proper error \(error)")
        }
    }
    
    func testErrorPropagationAtScanInProgress() {
        let observer = setUpScanForPeripherals(withServices: nil, options: nil)
        centralManagerMock.state = .poweredOn
        self.manager.scanForPeripherals(withServices: nil, options: nil).subscribe().disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(observer.events.count, 1, "should get ongoing error event")
        XCTAssertError(observer.events[0].value, _BluetoothError.scanInProgress, "should get proper ongoing error event")
    }
    
    func testProperScanMethodCall() {
        let args1 = (
            cbuuids: nil as [CBUUID]?,
            options: nil as [String: Any]?
        )
        let args2 = (
            cbuuids: [CBUUID(), CBUUID()],
            options: ["key": "value"] as [String: Any]
        )
        
        _ = setUpScanForPeripherals(withServices: args1.cbuuids, options: args1.options)
        centralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(centralManagerMock.scanForPeripheralsParams.count, 1, "should call scan for peripherals")
        XCTAssertNil(centralManagerMock.scanForPeripheralsParams[0].0, "should call with nil cbuuids")
        XCTAssertNil(centralManagerMock.scanForPeripheralsParams[0].1, "should call with nil options")
        
        _ = setUpScanForPeripherals(withServices: args2.cbuuids, options: args2.options)
        centralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(centralManagerMock.scanForPeripheralsParams.count, 1, "should call scan for peripherals")
        XCTAssertEqual(centralManagerMock.scanForPeripheralsParams[0].0!, args2.cbuuids, "should call with correct cbuuids")
        XCTAssertEqual(centralManagerMock.scanForPeripheralsParams[0].1!.count, args2.options.count, "should call with correct options")
    }
    
    typealias DiscoverResult = (CBPeripheralMock, [String: Any], NSNumber)
    func testPeripheralDiscovered() {
        let observer = setUpScanForPeripherals(withServices: nil, options: nil)
        centralManagerMock.state = .poweredOn
        let peripheralMocks = [CBPeripheralMock(), CBPeripheralMock(), CBPeripheralMock()]
        let events: [Recorded<Event<DiscoverResult>>] = [
            next(subscribeTime - 100, (peripheralMocks[0], [:], 10)),
            next(subscribeTime + 100, (peripheralMocks[1], [CBAdvertisementDataLocalNameKey: "value1"], 20)),
            next(subscribeTime + 101, (peripheralMocks[2], [CBAdvertisementDataIsConnectable: true], 30)),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didDiscoverPeripheral).disposed(by: disposeBag)
        
        let expectedEvents: [Recorded<Event<_ScannedPeripheral>>] = [
            next(subscribeTime + 100, createScannedPeripheral(peripheralMocks[1], [CBAdvertisementDataLocalNameKey: "value1"], 20)),
            next(subscribeTime + 101, createScannedPeripheral(peripheralMocks[2], [CBAdvertisementDataIsConnectable: true], 20))
        ]
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(observer.events.count, 2, "should receive 2 scan events")
        for eventIndex in 0...(expectedEvents.count - 2) {
            let element = observer.events[eventIndex].value.element!
            let expected = expectedEvents[eventIndex].value.element!
            XCTAssertEqual(element.rssi, expected.rssi, "should receive correct rssi for event index \(eventIndex)")
            XCTAssertEqual(element.peripheral, expected.peripheral, "should receive correct peripheral for event index \(eventIndex)")
            XCTAssertEqual(element.advertisementData.localName, expected.advertisementData.localName, "should receive correct advertisement data for event index \(eventIndex)")
            XCTAssertEqual(element.advertisementData.isConnectable, expected.advertisementData.isConnectable, "should receive correct advertisement data for event index \(eventIndex)")
        }
    }
    
    // Mark: - Utilities
    
    private func createScannedPeripheral(_ peripheral: CBPeripheralMock, _ advertisementData: [String: Any], _ rssi: NSNumber) -> _ScannedPeripheral {
        return _ScannedPeripheral(
            peripheral: _Peripheral(manager: manager, peripheral: peripheral),
            advertisementData: AdvertisementData(advertisementData: advertisementData),
            rssi: rssi
        )
    }
    
    private func setUpScanForPeripherals(withServices services: [CBUUID]?, options: [String: Any]?) -> ScheduledObservable<_ScannedPeripheral> {
        setUpProperties()
        
        wrapperProviderMock.provideReturn = CBPeripheralDelegateWrapperMock()
        let peripheralsObserver: ScheduledObservable<_ScannedPeripheral> = testScheduler.scheduleObservable {
            self.manager.scanForPeripherals(withServices: services, options: options).asObservable()
        }
        return peripheralsObserver
    }
    
    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
