import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralIncludedServicesTest: BasePeripheralTest {
    var service: _Service!
    
    override func setUp() {
        super.setUp()
        
        let serviceMock = CBServiceMock()
        serviceMock.uuid = CBUUID(string: "0x0000")
        service = _Service(peripheral: peripheral, service: serviceMock)
        peripheral.peripheral.services = [serviceMock]
        peripheral.peripheral.state = .connected
    }
    
    func testDiscoverIncludedServices() {
        let mockServices = [
            createService(uuid: "0x0001"),
            createService(uuid: "0x0002")
        ]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 1, "should call discover included services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverIncludedServicesWithServiceList() {
        let mockServices = [
            createService(uuid: "0x0001"),
            createService(uuid: "0x0002")
        ]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices([mockServices[1].uuid], for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 1, "should call discover included services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: [mockServices[1].uuid])
    }
    
    func testDiscoverIncludedServicesWithCachedAllServices() {
        let mockServices = [
            createService(uuid: "0x0001"),
            createService(uuid: "0x0002")
        ]
        service.service.includedServices = mockServices
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(mockServices.map { $0.uuid }, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 0, "should not call discover included services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverIncludedServicesWithCachedSomeServices() {
        let mockServices = [
            createService(uuid: "0x0001"),
            createService(uuid: "0x0002")
        ]
        service.service.includedServices = [mockServices[0]]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(mockServices.map { $0.uuid }, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 1, "should call discover included services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoveryQueue() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        
        let obs0: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        let obs1: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices([mockServices[0].uuid], for: self.service).asObservable()
        }
        let obs2: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices([mockServices[1].uuid], for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.service.service.includedServices = [mockServices[0]]
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 300) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.asObserver().onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 3, "should call discover included services 3 times")
        XCTAssertEqual(obs0.events.count, 0, "should not receive event for first request")
        XCTAssertServiceList(observable: obs1, uuids: [mockServices[0].uuid])
        XCTAssertEqual(obs2.events.count, 0, "should not receive event for third request")
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertServiceList(observable: obs2, uuids: [mockServices[1].uuid] )
        XCTAssertEqual(obs0.events.count, 0, "should not receive event for first request")
        
        testScheduler.advanceTo(subscribeTime + 300)
        
        XCTAssertServiceList(observable: obs0, uuids: mockServices.map { $0.uuid } )
    }
    
    func testDiscoverIncludedServicesForDisconnectedPeripheral() {
        peripheral.peripheral.state = .disconnected
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralDisconnected(peripheral, nil), "should receive peripheral disconnected error")
    }

    func testDiscoverIncludedServicesForConnectedPeripheralAfterADisconnection() {
        let mockServices = [
            createService(uuid: "0x0000")
        ]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.centralManagerMock.delegateWrapper.didDisconnectPeripheral.onNext((self.peripheral.peripheral, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralDisconnected(peripheral, nil), "should receive peripheral disconnected error")
        
        // Check that after reconnection the service discovery still works
        let time = ObservableScheduleTimes(createTime: subscribeTime + 200, subscribeTime: subscribeTime + 300, disposeTime: subscribeTime + 1000)
        let obs1: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable(time: time) {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        
        testScheduler.advanceTo(subscribeTime + 400)
        
        testScheduler.scheduleAt(subscribeTime + 500) {
            self.service.service.includedServices = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverIncludedServicesForService.onNext((self.service.service, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 600)
        
        XCTAssertEqual(peripheral.peripheral.discoverIncludedServicesParams.count, 2, "should call discover services for the peripheral")
        XCTAssertServiceList(observable: obs1, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverIncludedServicesForDisabledBluetooth() {
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverIncludedServices(nil, for: self.service).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.centralManagerMock.delegateWrapper.didUpdateState.asObserver().onNext(.poweredOff)
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.bluetoothPoweredOff, "should receive bluetooth powered off error")
    }
    
    // MARK: - Utils
    
    private func XCTAssertServiceList(observable: ScheduledObservable<[_Service]>, uuids: [CBUUID], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(observable.events.count, 2, "should receive two events", file: file, line: line)
        XCTAssertTrue(observable.events[1].value.isCompleted, "second event should be completed", file: file, line: line)
        let observedServices = observable.events[0].value.element!
        XCTAssertEqual(observedServices.count, uuids.count, "should receive \(uuids.count) services", file: file, line: line)
        for idx in 0..<uuids.count {
            XCTAssertEqual(observedServices[idx].uuid, uuids[idx], "service \(idx) should have correct uuid", file: file, line: line)
        }
    }
}


