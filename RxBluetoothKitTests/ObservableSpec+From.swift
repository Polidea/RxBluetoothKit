//
//  ObservableSpec+From.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 09/03/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation


import Foundation
import Quick
import Nimble
@testable
import RxBluetoothKit
import RxTests
import RxSwift

class ObservableFromSpec: QuickSpec {
    
    func createRecords<T>(records: (Int, Event<T>)...) -> [Recorded<Event<T>>]{
        var array = [Recorded<Event<T>>]()
        for (time, event) in records {
            array.append(Recorded(time: time, event: event))
        }
        return array
    }
    
    override func spec() {
        var testScheduler : TestScheduler!
        
        beforeEach {
            testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        }
        
        describe("Observable.from extension for an array") {
            var observable : ScheduledObservable<Int>!
            
            context("when there are two .Next() events with content") {
                beforeEach {
                    let ob = testScheduler.createColdObservable(self.createRecords(
                        (100, .Next([1,2,3,4])),
                        (300, .Next([5,6,7])),
                        (350, .Completed)))
                    
                    observable = testScheduler.scheduleObservable { return Observable.from(ob.asObservable()) }
                    testScheduler.start()
                }
                
                it("should contain all elements from table and complete event") {
                    expect(observable.events.count).to(equal(8))
                }
                
                it("should have every element with correct value") {
                    for i in 0..<7 {
                        expect(observable.events[i].value.element).to(equal(i + 1))
                    }
                }
                
                it("should issue first four elements at the same time") {
                    let time = observable.events.first?.time
                    for i in 1..<4 {
                        expect(observable.events[i].time).to(equal(time))
                    }
                }
                
                it("should issue last three elements at the same time") {
                    let time = observable.events[4].time
                    for i in 5..<7 {
                        expect(observable.events[i].time).to(equal(time))
                    }
                }
                
                it("should issue first four elements before other ones") {
                    expect(observable.events.first?.time).to(beLessThan(observable.events[4].time))
                }
                
                it("should register last event as complete event") {
                    expect(observable.events.last!.value == .Completed).to(beTrue())
                }
            }
            
            context("when there is a stream completed with error") {
                enum SomeError : ErrorType { case Error }
                
                beforeEach {
                    let ob = testScheduler.createColdObservable(self.createRecords(
                        (100, .Next([1,2])),
                        (150, .Next([])),
                        (200, .Next([3,4])),
                        (350, .Error(SomeError.Error))))
                    
                    observable = testScheduler.scheduleObservable { return Observable.from(ob.asObservable()) }
                    testScheduler.start()
                }
                
                it("should register correct numer of events") {
                    expect(observable.events.count).to(equal(5))
                }
                
                it("should have correct number for every event") {
                    for i in 0..<4 {
                        expect(observable.events[i].value.element).to(equal(i + 1))
                    }
                }
                
                it("should complete with an error") {
                    expect(observable.events.last!.value == .Error(SomeError.Error)).to(beTrue())
                }
            }
            
            context("when stream is disposed in the middle of processing") {
                beforeEach {
                    let ob = testScheduler.createColdObservable(self.createRecords(
                        (400, .Next([1,2])),
                        (850, .Next([])),
                        (1200, .Next([3,4])),
                        (1500, .Completed)))

                    observable = testScheduler.scheduleObservable { return Observable.from(ob.asObservable()) }
                    testScheduler.start()
                }
                
                it("should register only events which where emited before disposal") {
                    expect(observable.events.count).to(equal(2))
                }
                
                it("should have proper value for every emitted event") {
                    for i in 0..<2 {
                        expect(observable.events[i].value.element).to(equal(i + 1))
                    }
                }
            }
        }
    }
}