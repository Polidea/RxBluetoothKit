import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift

class PeripheralTest: BasePeripheralTest {
    func testObserveConnection() {
        let obs: ScheduledObservable<Bool> = testScheduler.scheduleObservable {
            self.peripheral.observeConnection().asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.centralManagerMock.delegateWrapper.didConnectPeripheral.asObserver().onNext(self.peripheral.peripheral)
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            self.centralManagerMock.delegateWrapper.didDisconnectPeripheral.asObserver().onNext((self.peripheral.peripheral, nil))
        }
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should reveive 2 events")
        XCTAssertTrue(obs.events[0].value.element!, "first element should be true")
        XCTAssertFalse(obs.events[1].value.element!, "second element should be false")
    }
    
    func testReadRSSI() {
        peripheral.peripheral.state = .connected
        let obs: ScheduledObservable<(_Peripheral, Int)> = testScheduler.scheduleObservable {
            self.peripheral.readRSSI().asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidReadRSSI.asObserver().onNext((100, nil))
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(peripheral.peripheral.readRSSIParams.count, 1, "should call readRSSI method for peripheral")
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        let params = obs.events[0].value.element!
        XCTAssertTrue(params.0 == peripheral && params.1 == 100, "should event with correct peripheral and rssi value")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receive completed event")
    }
    
    func testObserveNameUpdate() {
        peripheral.peripheral.state = .connected
        let obs: ScheduledObservable<(_Peripheral, String?)> = testScheduler.scheduleObservable {
            self.peripheral.observeNameUpdate()
        }
        let name = "testName"
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateName.asObserver().onNext(name)
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        let params = obs.events[0].value.element!
        XCTAssertTrue(params.0 == peripheral && params.1 == name, "should event with correct peripheral and name value")
    }
}
