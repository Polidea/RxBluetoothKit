import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

extension StartAdvertisingResult: Equatable {}
public func == (lhs: StartAdvertisingResult, rhs: StartAdvertisingResult) -> Bool {
    switch (lhs, rhs) {
    case (.started, .started): return true
    default: return false
    }
}

class PeripheralManagerTest_StartAdvertising: BasePeripheralManagerTest {

    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed

    func testErrorPropagationAtStart() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let observer = setUpStartAdvertising(nil)
            let (state, error) = stateWithError

            peripheralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)

            XCTAssertEqual(observer.events.count, 1, "should get error for state \(state)")
            XCTAssertError(observer.events[0].value, error, "should get proper error \(error)")
            XCTAssertFalse(manager.isAdvertisingOngoing, "should not set isAdvertisingOngoing")
        }
    }

    func testErrorPropagationAtAdvertisingInProgress() {
        let observer = setUpStartAdvertising(nil)
        peripheralManagerMock.state = .poweredOn
        self.manager.startAdvertising(nil).subscribe().disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(observer.events.count, 1, "should get ongoing error event")
        XCTAssertError(observer.events[0].value, _BluetoothError.advertisingInProgress, "should get proper ongoing error event")
        XCTAssertTrue(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")
    }

    func testProperScanMethodCall() {
        let args1: [String: Any]? = nil
        let args2: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "6B66A7A9-C4F3-4C2A-811A-79EFB7B8A85F")]]

        _ = setUpStartAdvertising(args1)
        peripheralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheralManagerMock.startAdvertisingParams.count, 1, "should call start advertising")
        XCTAssertNil(peripheralManagerMock.startAdvertisingParams[0], "should call with nil advertisementData")
        XCTAssertTrue(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")

        _ = setUpStartAdvertising(args2)
        peripheralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheralManagerMock.startAdvertisingParams.count, 1, "should call start advertising")
        let param = peripheralManagerMock.startAdvertisingParams[0]
        let value = param?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        XCTAssertNotNil(value, "should call with correct advertisementData")
        XCTAssertEqual(value![0], CBUUID(string: "6B66A7A9-C4F3-4C2A-811A-79EFB7B8A85F"))
        XCTAssertTrue(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")
    }

    func testProperAttachedToExternalAdvertisingResult() {
        let observer = setUpStartAdvertising(nil)
        peripheralManagerMock.state = .poweredOn
        peripheralManagerMock.isAdvertising = true
        manager.restoredAdvertisementData = [:]

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(observer.events.count, 1, "should get attached to external advertising result")
        XCTAssertNotNil(observer.events[0].value.element, "should get attached to external advertising result")
        let ongoing: Bool
        if case StartAdvertisingResult.attachedToExternalAdvertising(let result) = observer.events[0].value.element! {
            ongoing = result != nil
        } else {
            ongoing = false
        }
        XCTAssertTrue(ongoing, "should get attached to external advertising result")
    }

    func testThrowErrorWhenStartAdvertisingFailed() {
        let observer = setUpStartAdvertising(nil)
        peripheralManagerMock.state = .poweredOn
        let events: [Recorded<Event<Error?>>] = [
            next(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didStartAdvertising).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(observer.events.count, 1, "should get advertising start failed")
        XCTAssertError(observer.events[0].value, _BluetoothError.advertisingStartFailed(TestError.error), "should get proper advertising start error event")
    }

    func testStartAdvertisingSucceeded() {
        let observer = setUpStartAdvertising(nil)
        peripheralManagerMock.state = .poweredOn
        let events: [Recorded<Event<Error?>>] = [
            next(subscribeTime + 100, nil)
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didStartAdvertising).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(observer.events.count, 1, "should get started advertising result")
        XCTAssertEqual(observer.events[0].value.element!, StartAdvertisingResult.started, "should get started advertising result")
        XCTAssertTrue(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")
    }

    func testShouldCorrectlyHandleDispose() {
        _ = setUpStartAdvertising(nil)

        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime)
        XCTAssertTrue(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")

        testScheduler.advanceTo(TestScheduler.Defaults.disposed)

        XCTAssertFalse(manager.isAdvertisingOngoing, "should set isAdvertisingOngoing to true")
        XCTAssertEqual(peripheralManagerMock.stopAdvertisingParams.count, 1, "should call stopAdvertising")
    }

    // Mark: - Utilities

    private func setUpStartAdvertising(_ advertisementData: [String: Any]?) -> ScheduledObservable<StartAdvertisingResult> {
        setUpProperties()

        let observer: ScheduledObservable<StartAdvertisingResult> = testScheduler.scheduleObservable {
            self.manager.startAdvertising(advertisementData)
        }
        return observer
    }

    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
