//
//  ObservableSpec+QueueSubscribeOn.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 07/03/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

import Quick
import Nimble
@testable
import RxBluetoothKit
import RxTests
import RxSwift

class ObservableQueueSubscribeOnSpec: QuickSpec {
    
    func createRecords<T>(records: (Int, Event<T>)...) -> [Recorded<Event<T>>]{
        var array = [Recorded<Event<T>>]()
        for (time, event) in records {
            array.append(Recorded(time: time, event: event))
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
                        self.createRecords((000, .Next(-1)),
                                           (100, .Next(0)),
                                           (250, .Next(2)),
                                           (300, .Completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob1.queueSubscribeOn(serializedQueue).asObservable()
                    })
                    
                    let ob2 = testScheduler.createColdObservable(
                        self.createRecords((000, .Next(-1)),
                                           (050, .Next(1)),
                                           (100, .Completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob2.queueSubscribeOn(serializedQueue).asObservable()
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
                        self.createRecords((000, .Next(-1)),
                                           (205, .Next(0)),
                                           (250, .Next(2)),
                                           (400, .Completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob1.queueSubscribeOn(serializedQueue).asObservable()
                    })
                    
                    let ob2 = testScheduler.createHotObservable(
                        self.createRecords((000, .Next(-1)),
                                           (250, .Next(1)),
                                           (500, .Next(2)),
                                           (650, .Next(3)),
                                           (800, .Completed)))
                    users.append(testScheduler.scheduleObservable {
                        return ob2.queueSubscribeOn(serializedQueue).asObservable()
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
                        expect(users[0].observer.events.last!.value == .Completed).to(beTrue())
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
                enum SomeError : ErrorType { case Error }
                
                beforeEach {
                    users = []
                    isSubscribed = []
                    
                    // First user
                    let ob1 = testScheduler.createColdObservable(
                        self.createRecords((300, Event<Int>.Completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[0] = true
                            return ob1.asObservable()
                        }.queueSubscribeOn(serializedQueue)
                    })
                    
                    // Second user
                    let ob2 = testScheduler.createColdObservable(
                        self.createRecords((250, Event<Int>.Error(SomeError.Error))))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[1] = true
                            return ob2.asObservable()
                            }.queueSubscribeOn(serializedQueue)
                    })
                    
                    // Third user (it should be disposed even before subscription)
                    let ob3 = testScheduler.createColdObservable(
                        self.createRecords((100, Event<Int>.Completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable(ObservableScheduleTimes(createTime: 0, subscribeTime: 200, disposeTime: 500)) {
                        return Observable.deferred {
                            isSubscribed[2] = true
                            return ob3.asObservable()
                            }.queueSubscribeOn(serializedQueue)
                    })
                    
                    // Fourth user
                    let ob4 = testScheduler.createColdObservable(
                        self.createRecords((100, Event<Int>.Completed)))
                    isSubscribed.append(false)
                    users.append(testScheduler.scheduleObservable {
                        return Observable.deferred {
                            isSubscribed[3] = true
                            return ob4.asObservable()
                            }.queueSubscribeOn(serializedQueue)
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
                        expect(users[0].events.first!.value == .Completed).to(beTrue())
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
                        expect(users[1].events.first!.value == .Error(SomeError.Error)).to(beTrue())
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