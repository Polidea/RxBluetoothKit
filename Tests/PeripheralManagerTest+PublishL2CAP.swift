import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit


class PeripheralManagerTest_PublishL2CAP: BasePeripheralManagerTest {

    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed

    func testErrorPropagationAtStart() {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let observer = setUpPublishL2CAP(true)
            let (state, error) = stateWithError

            peripheralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)

            XCTAssertEqual(observer.events.count, 1, "should get error for state \(state)")
            XCTAssertError(observer.events[0].value, error, "should get proper error \(error)")
        }
    }

    func testProperPublishL2CAPMethodCall() {
        let arg1 = true
        let arg2 = false

        _ = setUpPublishL2CAP(arg1)
        peripheralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheralManagerMock.publishL2CAPChannelParams.count, 1, "should call publishL2CAPChannel")
        XCTAssertTrue(peripheralManagerMock.publishL2CAPChannelParams[0], "should call with encryption")

        _ = setUpPublishL2CAP(arg2)
        peripheralManagerMock.state = .poweredOn
        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheralManagerMock.publishL2CAPChannelParams.count, 1, "should call publishL2CAPChannel")
        XCTAssertFalse(peripheralManagerMock.publishL2CAPChannelParams[0], "should call with no encryption")
    }

    func testThrowErrorWhenPublishL2CAPFailed() {
        let observer = setUpPublishL2CAP(true)
        peripheralManagerMock.state = .poweredOn
        let events: [Recorded<Event<(CBL2CAPPSM, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (10, TestError.error))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didPublishL2CAPChannel).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(observer.events.count, 1, "should get publishL2CAP start failed")
        XCTAssertError(observer.events[0].value, _BluetoothError.publishingL2CAPChannelFailed(10, TestError.error), "should get proper publishL2CAP error event")
    }

    func testPublishL2CAPSucceeded() {
        let observer = setUpPublishL2CAP(true)
        peripheralManagerMock.state = .poweredOn
        let events: [Recorded<Event<(CBL2CAPPSM, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (10, nil))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didPublishL2CAPChannel).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(observer.events.count, 1, "should get started publishL2CAP result")
        XCTAssertEqual(observer.events[0].value.element!, 10, "should get proper started publishL2CAP result")
    }

    func testShouldCorrectlyHandleDispose() {
        _ = setUpPublishL2CAP(true)
        peripheralManagerMock.state = .poweredOn
        let events: [Recorded<Event<(CBL2CAPPSM, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (10, nil))
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.didPublishL2CAPChannel).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 100)
        testScheduler.advanceTo(TestScheduler.Defaults.disposed)

        XCTAssertEqual(peripheralManagerMock.unpublishL2CAPChannelParams.count, 1, "should call unpublishL2CAPChannel")
        XCTAssertEqual(peripheralManagerMock.unpublishL2CAPChannelParams[0], 10, "should call unpublishL2CAPChannel with proper param")
    }

    // Mark: - Utilities

    private func setUpPublishL2CAP(_ encryption: Bool) -> ScheduledObservable<CBL2CAPPSM> {
        setUpProperties()

        let observer: ScheduledObservable<CBL2CAPPSM> = testScheduler.scheduleObservable {
            self.manager.publishL2CAPChannel(withEncryption: encryption)
        }
        return observer
    }

    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}
