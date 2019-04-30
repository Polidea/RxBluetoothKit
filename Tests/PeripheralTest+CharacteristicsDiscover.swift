import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralCharacteristicsDiscoverTest: BasePeripheralTest {
    var service: _Service!

    override func setUp() {
        super.setUp()

        let serviceMock = CBServiceMock()
        serviceMock.uuid = CBUUID(string: "0x0000")
        service = _Service(peripheral: peripheral, service: serviceMock)
        peripheral.peripheral.services = [serviceMock]
        peripheral.peripheral.state = .connected
    }

    func testDiscoverCharacteristics() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001"),
            createCharacteristic(uuid: "0x0002")
        ]

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams.count, 1, "should call discover characteristics for the peripheral")
        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams[0].1, service.service, "should call discover characteristics with for correct service")
        XCTAssertCharacteristicsList(observable: obs, uuids: mockCharacteristics.map { $0.uuid })
    }

    func testDiscoverCharacteristicsWithUUIDList() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001"),
            createCharacteristic(uuid: "0x0002")
        ]

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics([mockCharacteristics[1].uuid], for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams.count, 1, "should call discover characteristics for the peripheral")
        XCTAssertCharacteristicsList(observable: obs, uuids: [mockCharacteristics[1].uuid])
    }

    func testDiscoverCharacteristicsWithCachedAllCharacteristics() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001"),
            createCharacteristic(uuid: "0x0002")
        ]
        service.service.characteristics = mockCharacteristics

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(mockCharacteristics.map { $0.uuid }, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 0, "should not call discover characteristics for the peripheral")
        XCTAssertCharacteristicsList(observable: obs, uuids: mockCharacteristics.map { $0.uuid })
    }

    func testDiscoverCharacteristicsWithCachedSomeServices() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001"),
            createCharacteristic(uuid: "0x0002")
        ]
        service.service.characteristics = [mockCharacteristics[0]]

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(mockCharacteristics.map { $0.uuid }, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams.count, 1, "should call discover characteristics for the peripheral")
        XCTAssertCharacteristicsList(observable: obs, uuids: mockCharacteristics.map { $0.uuid })
    }
    
    func testDiscoveryQueue() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0000"),
            createCharacteristic(uuid: "0x0001")
        ]
        
        let obs0: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }
        let obs1: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics([mockCharacteristics[0].uuid], for: self.service).asObservable()
        }
        let obs2: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics([mockCharacteristics[1].uuid], for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.characteristics = [mockCharacteristics[0]]
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 300) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams.count, 3, "should call discover included services 3 times")
        XCTAssertEqual(obs0.events.count, 0, "should not receive event for first request")
        XCTAssertCharacteristicsList(observable: obs1, uuids: [mockCharacteristics[0].uuid])
        XCTAssertEqual(obs2.events.count, 0, "should not receive event for third request")
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertCharacteristicsList(observable: obs2, uuids: [mockCharacteristics[1].uuid] )
        XCTAssertEqual(obs0.events.count, 0, "should not receive event for first request")
        
        testScheduler.advanceTo(subscribeTime + 300)
        
        XCTAssertCharacteristicsList(observable: obs0, uuids: mockCharacteristics.map { $0.uuid } )
    }

    func testDiscoverCharacteristicsForDisconnectedPeripheral() {
        peripheral.peripheral.state = .disconnected

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralDisconnected(peripheral, nil), "should receive peripheral disconnected error")
    }

    func testDiscoverCharacteristicsForConnectedPeripheralAfterADisconnection() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0000"),
            createCharacteristic(uuid: "0x0001")
        ]

        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.centralManagerMock.delegateWrapper.didDisconnectPeripheral.onNext((self.peripheral.peripheral, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralDisconnected(peripheral, nil), "should receive peripheral disconnected error")
        
        // Check that after reconnection the service discovery still works
        let time = ObservableScheduleTimes(createTime: subscribeTime + 200, subscribeTime: subscribeTime + 300, disposeTime: subscribeTime + 1000)
        let obs1: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable(time: time) {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }
        
        testScheduler.advanceTo(subscribeTime + 400)
        
        testScheduler.scheduleAt(subscribeTime + 500) {
            self.service.service.characteristics = mockCharacteristics
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 600)
        
        XCTAssertEqual(peripheral.peripheral.discoverCharacteristicsParams.count, 2, "should call discover characteristics twice")
        XCTAssertCharacteristicsList(observable: obs1, uuids: mockCharacteristics.map { $0.uuid })
    }

    func testDiscoverCharacteristicsForDisabledBluetooth() {
        let obs: ScheduledObservable<[_Characteristic]> = testScheduler.scheduleObservable {
            self.peripheral.discoverCharacteristics(nil, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.centralManagerMock.delegateWrapper.didUpdateState.asObserver().onNext(.poweredOff)
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.bluetoothPoweredOff, "should receive bluetooth powered off error")
    }
    
    // MARK: - Utils

    private func XCTAssertCharacteristicsList(observable: ScheduledObservable<[_Characteristic]>, uuids: [CBUUID], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(observable.events.count, 2, "should receive two events", file: file, line: line)
        XCTAssertTrue(observable.events[1].value.isCompleted, "second event should be completed", file: file, line: line)
        let observedCharacteristics = observable.events[0].value.element!
        XCTAssertEqual(observedCharacteristics.count, uuids.count, "should receive \(uuids.count) characteristics", file: file, line: line)
        for idx in 0..<uuids.count {
            XCTAssertEqual(observedCharacteristics[idx].uuid, uuids[idx], "characteristic \(idx) should have correct uuid", file: file, line: line)
        }
    }
}
