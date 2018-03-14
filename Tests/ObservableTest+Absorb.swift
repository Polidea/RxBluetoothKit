import Foundation
import XCTest
import RxTest
import RxSwift
@testable
import RxBluetoothKit

class ObservableAbsorbTest: XCTestCase {
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    override func setUp() {
        super.setUp()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
    
    func testObserverReceivingValues() {
        let obs1 = testScheduler.createHotObservable(
            createEventRecords(records: (subscribeTime + 50, .next(0)),
                               (subscribeTime + 200, .next(2)),
                               (subscribeTime + 300, .next(3)),
                               (subscribeTime + 400, .completed)))
        let obs2 = testScheduler.createHotObservable(
            createEventRecords(records: (subscribeTime + 150, .next(1)),
                               (subscribeTime + 250, .completed)))
        
        let absorbObserver: ScheduledObservable<Int> = testScheduler.scheduleObservable() {
            Observable.absorb(obs1.asObservable(), obs2.asObservable())
        }
        testScheduler.advanceTo(subscribeTime + 400)
        
        XCTAssertEqual(absorbObserver.events.count, 4, "should receive 4 events")
        XCTAssertEqual(absorbObserver.events[0].time, subscribeTime + 50, "should get first event at time \(subscribeTime + 50)")
        XCTAssertEqual(absorbObserver.events[0].value.element!, 0, "first registered value should be 0")
        XCTAssertEqual(absorbObserver.events[1].time, subscribeTime + 150, "should get second event at time \(subscribeTime + 150)")
        XCTAssertEqual(absorbObserver.events[1].value.element!, 1, "second registered value should be 1")
        XCTAssertEqual(absorbObserver.events[2].time, subscribeTime + 200, "should get third event at time \(subscribeTime + 200)")
        XCTAssertEqual(absorbObserver.events[2].value.element!, 2, "third registered value should be 2")
        XCTAssertEqual(absorbObserver.events[3].time, subscribeTime + 250, "should get fourth event at time \(subscribeTime + 250)")
        XCTAssertTrue(absorbObserver.events[3].value == .completed, "fourt registered event should be completed event")
    }
    
    func testObserverReceivingError() {
        let obs1 = testScheduler.createHotObservable(
            createEventRecords(records: (subscribeTime + 50, .next(0)),
                                (subscribeTime + 200, .next(2)),
                                (subscribeTime + 250, .completed)))
        let obs2 = testScheduler.createHotObservable(
            createEventRecords(records: (subscribeTime + 100, .error(TestError.error)),
                                (subscribeTime + 150, .next(1)),
                                (subscribeTime + 250, .completed)))
        
        let absorbObserver: ScheduledObservable<Int> = testScheduler.scheduleObservable() {
            Observable.absorb(obs1.asObservable(), obs2.asObservable())
        }
        testScheduler.advanceTo(subscribeTime + 250)
        
        XCTAssertEqual(absorbObserver.events.count, 2, "should receive 2 events")
        XCTAssertEqual(absorbObserver.events[1].time, subscribeTime + 100, "should get last event at time \(subscribeTime + 100)")
        XCTAssertError(absorbObserver.events[1].value, TestError.error, "should get an error as a last event")
    }
}
