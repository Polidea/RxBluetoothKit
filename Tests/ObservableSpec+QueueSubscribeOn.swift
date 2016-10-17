// The MIT License (MIT)
//
// Copyright (c) 2016 Polidea
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

import Quick
import Nimble
@testable
import RxBluetoothKit
import RxTest
import RxSwift

class ObservableQueueSubscribeOnSpec: QuickSpec {
    
    func createRecords<T>(records: (Int, Event<T>)...) -> [Recorded<Event<T>>]{
        var array = [Recorded<Event<T>>]()
        for (time, event) in records {
            array.append(Recorded(time: time, value: event))
        }
        return array
    }
    
    override func spec() {
        var testScheduler: TestScheduler!
        
        beforeEach {
            testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        }
        
        describe("queueSubscribeOn extension") {
            var serializedQueue: SerializedSubscriptionQueue!
            var users: [ScheduledObservable<Int>]!
            
            beforeEach {
                serializedQueue = SerializedSubscriptionQueue(scheduler: testScheduler)
            }
            
            context("when there are two users registering cold subscriptions on queue") {
                beforeEach {
                    users = []
                    
                    let ob1 = testScheduler.createColdObservable(
                        self.createRecords(records: (000, .next(-1)),
                                           (100, .next(0)),
                                           (250, .next(2)),
                                           (300, .completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob1.queueSubscribe(on: serializedQueue).asObservable()
                    })
                    
                    let ob2 = testScheduler.createColdObservable(
                        self.createRecords(records: (000, .next(-1)),
                                           (050, .next(1)),
                                           (100, .completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob2.queueSubscribe(on: serializedQueue).asObservable()
                    })
                }
                
                it ("should register events only for first user before its complete event is emitted") {
                    testScheduler.advanceTo(users[0].subscribeTime + 250)
                    expect(users[0].observer.events.count).to(equal(3))
                    expect(users[1].observer.events.count).to(equal(0))
                }
                
                it ("should register first event for second user when first one finished emitting") {
                    testScheduler.advanceTo(users[0].subscribeTime + 300)
                    expect(users[0].observer.events.count).to(equal(4))
                    expect(users[1].observer.events.count).to(equal(1))
                }
                
                it ("should collect all events for both users after disposal of both users") {
                    testScheduler.advanceTo(users[1].disposeTime)
                    expect(users[0].observer.events.count).to(equal(4))
                    expect(users[1].observer.events.count).to(equal(3))
                }
            }
            
            context("when there are two users registering hot subscriptions on queue") {
                beforeEach {
                    users = []
                    
                    let ob1 = testScheduler.createHotObservable(
                        self.createRecords(records: (000, .next(-1)),
                                           (205, .next(0)),
                                           (250, .next(2)),
                                           (400, .completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob1.queueSubscribe(on: serializedQueue).asObservable()
                    })
                    
                    let ob2 = testScheduler.createHotObservable(
                        self.createRecords(records: (000, .next(-1)),
                                           (250, .next(1)),
                                           (500, .next(2)),
                                           (650, .next(3)),
                                           (800, .completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob2.queueSubscribe(on: serializedQueue).asObservable()
                    })
                }
                
                context("before first user completes its stream") {
                    beforeEach {
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should register two events for first user and none for second one") {
                        expect(users[0].observer.events.count).to(equal(2))
                        expect(users[1].observer.events.count).to(equal(0))
                    }
                    
                    it("should skip first user's first event because it's emitted before subscription") {
                        expect(users[0].observer.events[0].value.isStopEvent).to(beFalse())
                        expect(users[0].observer.events[0].value.element).to(equal(0))
                    }
                }
                
                context("after first user completes its stream") {
                    beforeEach {
                        testScheduler.advanceTo(400)
                    }
                    
                    it("should register three events for first user and none for second one") {
                        expect(users[0].observer.events.count).to(equal(3))
                        expect(users[1].observer.events.count).to(equal(0))
                    }
                    
                    it("should register last event of first user as complete of stream") {
                        expect(users[0].observer.events.last!.value == .completed).to(beTrue())
                    }
                }
                
                context("after last user completes its stream") {
                    beforeEach {
                        testScheduler.advanceTo(800)
                    }
                    
                    it("should register all possible events for both users") {
                        expect(users[0].observer.events.count).to(equal(3))
                        expect(users[1].observer.events.count).to(equal(3))
                    }
                    
                    it("should register event for second user as .Next(2)") {
                        expect(users[1].observer.events.first?.value.element).to(equal(2))
                    }
                }
            }
            
            context("when there are four users with queued subscriptions") {
                var isSubscribed : [Bool]!
                enum SomeError : Error { case error }
                
                beforeEach {
                    users = []
                    isSubscribed = []
                    
                    // First user
                    let ob1 = testScheduler.createColdObservable(
                        self.createRecords(records: (300, Event<Int>.completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[0] = true
                            return ob1.asObservable()
                        }.queueSubscribe(on: serializedQueue)
                    })
                    
                    // Second user
                    let ob2 = testScheduler.createColdObservable(
                        self.createRecords(records: (250, Event<Int>.error(SomeError.error))))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[1] = true
                            return ob2.asObservable()
                            }.queueSubscribe(on: serializedQueue)
                    })
                    
                    // Third user (it should be disposed even before subscription)
                    let ob3 = testScheduler.createColdObservable(
                        self.createRecords(records: (100, Event<Int>.completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable(time: ObservableScheduleTimes(createTime: 0, subscribeTime: 200, disposeTime: 500)) {
                        return Observable.deferred {
                            isSubscribed[2] = true
                            return ob3.asObservable()
                            }.queueSubscribe(on: serializedQueue)
                    })
                    
                    // Fourth user
                    let ob4 = testScheduler.createColdObservable(
                        self.createRecords(records: (100, Event<Int>.completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[3] = true
                            return ob4.asObservable()
                            }.queueSubscribe(on: serializedQueue)
                    })
                }
                
                context("before first user is subscribed") {
                    beforeEach {
                        testScheduler.advanceTo(users[0].time.before.subscribeTime)
                    }
                    
                    it("shouldn't subscribe any user") {
                        expect(isSubscribed[0]).to(beFalse())
                        expect(isSubscribed[1]).to(beFalse())
                        expect(isSubscribed[2]).to(beFalse())
                        expect(isSubscribed[3]).to(beFalse())
                    }
                }
                
                context("after first user is subscribed") {
                    beforeEach {
                        testScheduler.advanceTo(users[0].subscribeTime)
                    }
                    
                    it("should subscribe only first user") {
                        expect(isSubscribed[0]).to(beTrue())
                        expect(isSubscribed[1]).to(beFalse())
                        expect(isSubscribed[2]).to(beFalse())
                        expect(isSubscribed[3]).to(beFalse())
                    }
                    
                    it("shouldn't register any events for first user") {
                        expect(users[0].events.count).to(equal(0))
                    }
                }
                
                context("after first user completes its stream") {
                    beforeEach {
                        testScheduler.advanceTo(users[0].subscribeTime + 300)
                    }
                    
                    it("should register second user") {
                        expect(isSubscribed[0]).to(beTrue())
                        expect(isSubscribed[1]).to(beTrue())
                        expect(isSubscribed[2]).to(beFalse())
                        expect(isSubscribed[3]).to(beFalse())
                    }
                    
                    it("should register only complete event for first user") {
                        expect(users[0].events.first!.value == .completed).to(beTrue())
                    }
                    
                    it("shouldn't register any event for second user") {
                        expect(users[1].events.count).to(equal(0))
                    }
                }
                
                context("after second user completes its stream") {
                    beforeEach {
                        testScheduler.advanceTo(users[0].subscribeTime + 300 + 250)
                    }
                    
                    it ("should skip registration of third user and register fourth user immidiately") {
                        expect(isSubscribed[0]).to(beTrue())
                        expect(isSubscribed[1]).to(beTrue())
                        expect(isSubscribed[2]).to(beFalse())
                        expect(isSubscribed[3]).to(beTrue())
                    }
                    
                    it ("should register one event for second user") {
                        expect(users[1].events.first!.value == .error(SomeError.error)).to(beTrue())
                    }
                    
                    it ("shouldn't register any event for fourth user") {
                        expect(users[3].events.count).to(equal(0))
                    }
                }
                
                context("after all events are processed") {
                    beforeEach {
                        testScheduler.start()
                    }
                    
                    it("should subscribe to all events except thrid one") {
                        expect(isSubscribed[0]).to(beTrue())
                        expect(isSubscribed[1]).to(beTrue())
                        expect(isSubscribed[2]).to(beFalse())
                        expect(isSubscribed[3]).to(beTrue())
                    }
                    
                    it("should contain valid number of events for every user") {
                        expect(users[0].events.count).to(equal(1))
                        expect(users[1].events.count).to(equal(1))
                        expect(users[2].events.count).to(equal(0))
                        expect(users[3].events.count).to(equal(1))
                    }
                }
            }
        }
    }
}
