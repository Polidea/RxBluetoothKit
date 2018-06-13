import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

class PeripheralManagerTest_AddService: BasePeripheralManagerTest {

    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed

    func testBluetoothError() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let obs = setUpAddService(createMutableService())
            let (state, error) = stateWithError

            peripheralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)

            XCTAssertEqual(obs.events.count, 1, "should get error for state \(state)")
            XCTAssertError(obs.events[0].value, error, "should get proper error \(error)")
            XCTAssertEqual(peripheralManagerMock.addParams.count, 0, "should not call addService")
        }
    }

    func testObserveError() {
        let service = createMutableService()
        let obs = setUpAddService(service)
        let events: [Recorded<Event<(CBServiceMock, Error?)>>] = [
            error(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didAddService).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should get only one error event")
        XCTAssertNotNil(obs.events[0].value.error, "should get error")
        XCTAssertError(obs.events[0].value, TestError.error)
        XCTAssertEqual(peripheralManagerMock.addParams.count, 1, "should call addService")
        XCTAssertEqual(peripheralManagerMock.addParams[0], service, "should call addService with proper param")
    }

    func testAddServiceError() {
        let service = createMutableService()
        let obs = setUpAddService(service)
        let resultServiceMock = CBServiceMock()
        resultServiceMock.uuid = createUuid()
        let events: [Recorded<Event<(CBServiceMock, Error?)>>] = [
            next(subscribeTime + 100, (resultServiceMock, TestError.error))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didAddService).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should get only one error event")
        XCTAssertNotNil(obs.events[0].value.error, "should get error")
        XCTAssertError(obs.events[0].value, _BluetoothError.addingServiceFailed(resultServiceMock, TestError.error))
        XCTAssertEqual(peripheralManagerMock.addParams.count, 1, "should call addService")
        XCTAssertEqual(peripheralManagerMock.addParams[0], service, "should call addService with proper param")
    }

    func testAddServiceErrorForDifferentService() {
        let service = createMutableService()
        let obs = setUpAddService(service)
        let resultServiceMock = CBServiceMock()
        resultServiceMock.uuid = CBUUID(string: "D7E9576D-B058-4704-B60B-DF5AD022A9F1")
        let events: [Recorded<Event<(CBServiceMock, Error?)>>] = [
            next(subscribeTime + 100, (resultServiceMock, TestError.error))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didAddService).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 0, "should not get any event")
        XCTAssertEqual(peripheralManagerMock.addParams.count, 1, "should call addService")
        XCTAssertEqual(peripheralManagerMock.addParams[0], service, "should call addService with proper param")
    }

    func testAddServiceSuccess() {
        let service = createMutableService()
        let obs = setUpAddService(service)
        let resultServiceMock = CBServiceMock()
        resultServiceMock.uuid = createUuid()
        let events: [Recorded<Event<(CBServiceMock, Error?)>>] = [
            next(subscribeTime + 100, (resultServiceMock, nil))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didAddService).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 2, "should get success and completed event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, resultServiceMock.uuid, "should receive success event with proper param")
        XCTAssertTrue(obs.events[1].value.isCompleted, "shoudl receive completed event")
        XCTAssertEqual(peripheralManagerMock.addParams.count, 1, "should call addService")
        XCTAssertEqual(peripheralManagerMock.addParams[0], service, "should call addService with proper param")
    }

    // Mark: - Utilities

    func setUpAddService(_ service: CBMutableService) -> ScheduledObservable<CBServiceMock> {
        setUpProperties()

        let addServiceObservable: ScheduledObservable<CBServiceMock> = testScheduler.scheduleObservable {
            self.manager.add(service).asObservable()
        }

        return addServiceObservable
    }

    func createMutableService() -> CBMutableService {
        return CBMutableService(type: createUuid(), primary: true)
    }

    func createUuid() -> CBUUID {
        return CBUUID(string: "242D246C-F5CE-49B0-BF83-666CB1A44C88")
    }

    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}


