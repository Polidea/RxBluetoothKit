import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

typealias SubscribeParam = (CBCentralMock, CBCharacteristicMock)
func ==(l:SubscribeParam,r:SubscribeParam) -> Bool {
    return l.0 == l.0 && r.1 == r.1
}

class PeripheralManagerTest_Observables: BasePeripheralManagerTest {

    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed

    func testDidReceiveReadError() {
        testBluetoothError {
            setUpObservable { self.manager.observeDidReceiveRead() }
        }
    }

    func testDidReceiveReadObserveError() {
        testObserveError(observableCreator: {
            setUpObservable { self.manager.observeDidReceiveRead() }
        }, retrieveSubject: { self.wrapperMock.didReceiveRead })
    }

    func testDidReceiveReadObserveSuccess() {
        let request = CBATTRequestMock()
        testObserveSuccess(observableCreator: {
            setUpObservable { self.manager.observeDidReceiveRead() }
        }, success: request, retrieveSubject: { self.wrapperMock.didReceiveRead })
    }

    func testDidReceiveWriteError() {
        testBluetoothError {
            setUpObservable { self.manager.observeDidReceiveWrite() }
        }
    }

    func testDidReceiveWriteObserveError() {
        testObserveError(observableCreator: {
            setUpObservable { self.manager.observeDidReceiveWrite() }
        }, retrieveSubject: { self.wrapperMock.didReceiveWrite })
    }

    func testDidReceiveWriteObserveSuccess() {
        let request = [CBATTRequestMock()]
        testObserveSuccess(observableCreator: {
            setUpObservable { self.manager.observeDidReceiveWrite() }
        }, success: request, retrieveSubject: { self.wrapperMock.didReceiveWrite })
    }

    func testIsReadyToUpdateSubscribersError() {
        testBluetoothError {
            setUpObservable { self.manager.observeIsReadyToUpdateSubscribers() }
        }
    }

    func testIsReadyToUpdateSubscribersObserveError() {
        testObserveError(observableCreator: {
            setUpObservable { self.manager.observeIsReadyToUpdateSubscribers() }
        }, retrieveSubject: { self.wrapperMock.isReady })
    }

    func testOnSubscribeError() {
        testBluetoothError {
            setUpObservable { self.manager.observeOnSubscribe() }
        }
    }

    func testOnSubscribeObserveError() {
        testObserveError(observableCreator: {
            setUpObservable { self.manager.observeOnSubscribe() }
        }, retrieveSubject: { self.wrapperMock.didSubscribeTo })
    }

    func testOnSubscribeObserveSuccess() {
        let arg: SubscribeParam = (CBCentralMock(), CBCharacteristicMock())
        let elementEqual = { (l: SubscribeParam, r: SubscribeParam) -> Bool in l == r }
        testObserveSuccess(observableCreator: {
            setUpObservable { self.manager.observeOnSubscribe() }
        }, success: arg, retrieveSubject: { self.wrapperMock.didSubscribeTo }, elementEqual: elementEqual)
    }

    func testOnUnSubscribeError() {
        testBluetoothError {
            setUpObservable { self.manager.observeOnUnsubscribe() }
        }
    }

    func testOnUnSubscribeObserveError() {
        testObserveError(observableCreator: {
            setUpObservable { self.manager.observeOnUnsubscribe() }
        }, retrieveSubject: { self.wrapperMock.didUnsubscribeFrom })
    }

    func testOnUnSubscribeObserveSuccess() {
        let arg: (CBCentralMock, CBCharacteristicMock) = (CBCentralMock(), CBCharacteristicMock())
        let elementEqual = { (l: SubscribeParam, r: SubscribeParam) -> Bool in l == r }
        testObserveSuccess(observableCreator: {
            setUpObservable { self.manager.observeOnUnsubscribe() }
        }, success: arg, retrieveSubject: { self.wrapperMock.didUnsubscribeFrom }, elementEqual: elementEqual)
    }

    #if os(iOS) || os(tvOS) || os(watchOS)

    func testDidOpenChannelError() {

        testBluetoothError {
            setUpObservable(creator: { () -> Observable<(CBL2CAPChannelMock?, Error?)> in
                self.wrapperMock.didOpenChannel = PublishSubject<(CBL2CAPChannelMock?, Error?)>()
                return self.manager.observeDidOpenL2CAPChannel()
            })
        }
    }

    func testDidOpenChannelObserveError() {
        testObserveError(observableCreator: {
            setUpObservable(creator: { () -> Observable<(CBL2CAPChannelMock?, Error?)> in
                return self.manager.observeDidOpenL2CAPChannel()
            })
        }, retrieveSubject: { () -> PublishSubject<(CBL2CAPChannelMock?, Error?)> in
            self.wrapperMock.didOpenChannel = PublishSubject<(CBL2CAPChannelMock?, Error?)>()
            return self.wrapperMock.didOpenChannel
        })
    }

    #endif

    // Mark: - Utilities

    private func testBluetoothError<T>(observableCreator: () -> ScheduledObservable<T>) {
        for stateWithError in _BluetoothError.invalidStateErrors {
            let obs = observableCreator()
            let (state, error) = stateWithError

            peripheralManagerMock.state = state

            testScheduler.advanceTo(subscribeTime)

            XCTAssertEqual(obs.events.count, 1, "should get error for state \(state)")
            XCTAssertError(obs.events[0].value, error, "should get proper error \(error)")
        }
    }

    private func testObserveError<T>(observableCreator: () -> ScheduledObservable<T>, retrieveSubject: () -> PublishSubject<T>) {
        let obs = observableCreator()
        let events: [Recorded<Event<T>>] = [
            Recorded.error(subscribeTime + 100, TestError.error)
        ]
        testScheduler.createHotObservable(events).subscribe(retrieveSubject()).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should get only one error event")
        XCTAssertNotNil(obs.events[0].value.error, "should get error")
        XCTAssertError(obs.events[0].value, TestError.error)
    }

    private func testObserveSuccess<T: Equatable>(observableCreator: () -> ScheduledObservable<T>, success: T, retrieveSubject: () -> PublishSubject<T>) {
        return testObserveSuccess(observableCreator: observableCreator, success: success, retrieveSubject: retrieveSubject) {
            $0 == $1
        }
    }

    private func testObserveSuccess<T>(observableCreator: () -> ScheduledObservable<T>, success: T, retrieveSubject: () -> PublishSubject<T>, elementEqual: (T, T) -> Bool) {
        let obs = observableCreator()
        let events: [Recorded<Event<T>>] = [
            Recorded.next(subscribeTime + 100, success)
        ]
        testScheduler.createHotObservable(events).subscribe(retrieveSubject()).disposed(by: disposeBag)
        peripheralManagerMock.state = .poweredOn

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should get only one success event")
        XCTAssertTrue(elementEqual(obs.events[0].value.element!, success), "should get proper success event param")
    }

    func setUpObservable<Element>(creator: @escaping () -> Observable<Element>) -> ScheduledObservable<Element> {
        setUpProperties()
        return testScheduler.scheduleObservable(create: creator) as ScheduledObservable<Element>
    }

    override func setUpProperties() {
        super.setUpProperties()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
}


