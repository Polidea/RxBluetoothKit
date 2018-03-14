import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralServiceTest: BasePeripheralTest {
    
    override func setUp() {
        super.setUp()
        
        peripheral.peripheral.state = .connected
    }
    
    func testDiscoverServices() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices(nil).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext((mockServices, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverServicesParams.count, 1, "should call discover services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverServicesWithServiceList() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices([mockServices[1].uuid]).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext((mockServices, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverServicesParams.count, 1, "should call discover services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: [mockServices[1].uuid])
    }
    
    func testDiscoverServicesWithCachedAllServices() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        self.peripheral.peripheral.services = mockServices
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices(
                mockServices.map { $0.uuid }
            ).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext((mockServices, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverServicesParams.count, 0, "should not call discover services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverServicesWithCachedSomeServices() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        self.peripheral.peripheral.services = [mockServices[0]]
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices(
                mockServices.map { $0.uuid }
            ).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext((mockServices, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverServicesParams.count, 1, "should call discover services for the peripheral")
        XCTAssertServiceList(observable: obs, uuids: mockServices.map { $0.uuid })
    }
    
    func testDiscoverServicesForDisconnectedPeripheral() {
        peripheral.peripheral.state = .disconnected
        
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices(nil).asObservable()
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, _BluetoothError.peripheralDisconnected(peripheral, nil), "should receive peripheral disconnected error")
    }
    
    func testDiscoverServicesForDisabledBluetooth() {
        let obs: ScheduledObservable<[_Service]> = testScheduler.scheduleObservable {
            self.peripheral.discoverServices(nil).asObservable()
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

