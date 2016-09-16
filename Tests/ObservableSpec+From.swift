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
                        records: (100, .next([1,2,3,4])),
                        (300, .next([5,6,7])),
                        (350, .completed)))
                    
                    observable = testScheduler.scheduleObservable {
                        return ob.flatMap({ (array) -> Observable<Int> in
                            return Observable.from(array)
                        })
                    }
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
                    expect(observable.events.last!.value == .completed).to(beTrue())
                }
            }
            
            context("when there is a stream completed with error") {
                enum SomeError : Error { case error }
                
                beforeEach {
                    let ob = testScheduler.createColdObservable(self.createRecords(
                        records: (100, .next([1,2])),
                        (150, .next([])),
                        (200, .next([3,4])),
                        (350, .error(SomeError.error))))
                    
                    observable = testScheduler.scheduleObservable {
                        return ob.flatMap({ (array) -> Observable<Int> in
                            return Observable.from(array)
                        })
                    }
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
                    expect(observable.events.last!.value == .error(SomeError.error)).to(beTrue())
                }
            }
            
            context("when stream is disposed in the middle of processing") {
                beforeEach {
                    let ob = testScheduler.createColdObservable(self.createRecords(
                        records: (400, .next([1,2])),
                        (850, .next([])),
                        (1200, .next([3,4])),
                        (1500, .completed)))

                    observable = testScheduler.scheduleObservable {
                        return ob.flatMap({ (array) -> Observable<Int> in
                            return Observable.from(array)
                        })
                    }
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
