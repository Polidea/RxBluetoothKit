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

import Foundation

@testable
import RxBluetoothKit
import RxTest
import RxSwift
import XCTest

enum SomeError: Error { case error }

class ObservableQueueSubscribeOnTest: XCTestCase {
    
    var serializedQueue: SerializedSubscriptionQueue!
    
    var testScheduler: TestScheduler!
    
    private func createRecords<T>(records: (Int, Event<T>)...) -> [Recorded<Event<T>>] {
        var array = [Recorded<Event<T>>]()
        for (time, event) in records {
            array.append(Recorded(time: time, value: event))
        }
        return array
    }
    
    override func setUp() {
        super.setUp()
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        serializedQueue = SerializedSubscriptionQueue(scheduler: testScheduler)
    }
    
    func testTwoUsersRegisteringColdSubscription() {
        let ob1 = testScheduler.createColdObservable(
            self.createRecords(records: (000, .next(-1)),
                               (100, .next(0)),
                               (250, .next(2)),
                               (300, .completed)))
        let ob2 = testScheduler.createColdObservable(
            self.createRecords(records: (000, .next(-1)),
                               (050, .next(1)),
                               (100, .completed)))
        let user1 = testScheduler.scheduleObservable {
            ob1.queueSubscribe(on: self.serializedQueue).asObservable()
        }
        let user2 = testScheduler.scheduleObservable {
            ob2.queueSubscribe(on: self.serializedQueue).asObservable()
        }
        
        testScheduler.advanceTo(user1.subscribeTime + 250)
        
        XCTAssertEqual(user1.observer.events.count, 3, "should register 3 events for first user")
        XCTAssertEqual(user2.observer.events.count, 0, "should register no events for second user")
        
        testScheduler.advanceTo(user1.subscribeTime + 300)
        
        XCTAssertEqual(user1.observer.events.count, 4, "should register 4 events for first user")
        XCTAssertEqual(user2.observer.events.count, 1, "should register 1 events for second user")
        
        testScheduler.advanceTo(user2.disposeTime)
        
        XCTAssertEqual(user1.observer.events.count, 4, "should register 4 events for first user")
        XCTAssertEqual(user2.observer.events.count, 3, "should register 3 events for second user")
    }
    
    func testTwoUsersRegisteringHotSubscription() {
        let ob1 = testScheduler.createHotObservable(
            self.createRecords(records: (000, .next(-1)),
                               (205, .next(0)),
                               (250, .next(2)),
                               (400, .completed)))
        let ob2 = testScheduler.createHotObservable(
            self.createRecords(records: (000, .next(-1)),
                               (250, .next(1)),
                               (500, .next(2)),
                               (650, .next(3)),
                               (800, .completed)))
        let user1 = testScheduler.scheduleObservable {
            ob1.queueSubscribe(on: self.serializedQueue).asObservable()
        }
        let user2 = testScheduler.scheduleObservable {
            ob2.queueSubscribe(on: self.serializedQueue).asObservable()
        }
        
        testScheduler.advanceTo(250)
        
        XCTAssertEqual(user1.observer.events.count, 2, "should register 2 events for first user")
        XCTAssertEqual(user2.observer.events.count, 0, "should register none event for second user")
        XCTAssertFalse(user1.observer.events[0].value.isStopEvent, "should skip first user's first event because it is emited before subscription")
        XCTAssertEqual(user1.observer.events[0].value.element, 0, "should skip first user's first event because it is emited before subscription")
        
        testScheduler.advanceTo(400)
        
        XCTAssertEqual(user1.observer.events.count, 3, "should register all events for first user")
        XCTAssertEqual(user2.observer.events.count, 0, "should register none event for second user")
        XCTAssertTrue(user1.observer.events.last!.value == .completed, "should register last event of first user as complete of stream")
        
        testScheduler.advanceTo(800)
        
        XCTAssertEqual(user1.observer.events.count, 3, "should register all events for first user")
        XCTAssertEqual(user2.observer.events.count, 3, "should register all events for second user")
        XCTAssertEqual(user2.observer.events.first?.value.element, 2, "should register event for second user as .Next(2)")
    }
    
    func testFourUsersWithQueuedSubscription() {
        var isUserSubscribed = [false, false, false, false]
        let ob1 = testScheduler.createColdObservable(self.createRecords(records: (300, Event<Int>.completed)))
        let user1 = testScheduler.scheduleObservable {
            Observable.deferred { () -> Observable<Int> in
                isUserSubscribed[0] = true
                return ob1.asObservable()
                }.queueSubscribe(on: self.serializedQueue)
        }
        let ob2 = testScheduler.createColdObservable(self.createRecords(records: (250, Event<Int>.error(SomeError.error))))
        let user2 = testScheduler.scheduleObservable {
            Observable.deferred { () -> Observable<Int> in
                isUserSubscribed[1] = true
                return ob2.asObservable()
                }.queueSubscribe(on: self.serializedQueue)
        }
        let ob3 = testScheduler.createColdObservable(self.createRecords(records: (100, Event<Int>.completed)))
        let user3 = testScheduler.scheduleObservable(time: ObservableScheduleTimes(createTime: 0, subscribeTime: 200, disposeTime: 500)) {
            Observable.deferred { () -> Observable<Int> in
                isUserSubscribed[2] = true
                return ob3.asObservable()
                }.queueSubscribe(on: self.serializedQueue)
        }
        let ob4 = testScheduler.createColdObservable(self.createRecords(records: (100, Event<Int>.completed)))
        let user4 = testScheduler.scheduleObservable {
            Observable.deferred { () -> Observable<Int> in
                isUserSubscribed[3] = true
                return ob4.asObservable()
                }.queueSubscribe(on: self.serializedQueue)
        }
        
        testScheduler.advanceTo(user1.time.before.subscribeTime)
        
        XCTAssertEqual(isUserSubscribed, [false, false, false, false], "shouldn't subscribe any user")
        
        testScheduler.advanceTo(user1.subscribeTime)
        
        XCTAssertEqual(isUserSubscribed, [true, false, false, false], "should subscribe only first user")
        XCTAssertEqual(user1.events.count, 0, "shouldn't register any events for first user")
        
        testScheduler.advanceTo(user1.subscribeTime + 300)
        
        XCTAssertEqual(isUserSubscribed, [true, true, false, false], "should subscribe first and second user")
        XCTAssertTrue(user1.events.first!.value == .completed, "should register only complete event for first user")
        XCTAssertEqual(user2.events.count, 0, "shouldn't register any event for second user")
        
        testScheduler.advanceTo(user1.subscribeTime + 300 + 250)
        
        XCTAssertEqual(isUserSubscribed, [true, true, false, true], "should subscribe first, second and fourth user")
        XCTAssertTrue(user2.events.first!.value == .error(SomeError.error), "should register one event for second user")
        XCTAssertEqual(user4.events.count, 0, "shouldn't register any event for fourth user")
        
        testScheduler.start()
        XCTAssertEqual(isUserSubscribed, [true, true, false, true], "should subscribe to all events except thrid one")
        XCTAssertEqual(
            [user1.events.count, user2.events.count, user3.events.count, user4.events.count],
            [1, 1, 0, 1],
            "should contain valid number of events for every user"
        )
    }
}

