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
import RxTest
import RxSwift
import CoreBluetooth
import RxBluetoothKit
import XCTest

// Helps
final class Box<T> {
    let value: T

    init(value: T) {
        self.value = value
    }
}

func XCTAssertError<ErrorType: Equatable, Element>(_ event: Event<Element>, _ errorType: ErrorType, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(event.isStopEvent, message, file: file, line: line)
    XCTAssertNotNil(event.error, message, file: file, line: line)
    XCTAssertTrue(event.error is ErrorType, message, file: file, line: line)
    XCTAssertEqual(event.error as? ErrorType, errorType, message, file: file, line: line)
}

extension TestScheduler {
    func scheduleObservable<Element>(time: ObservableScheduleTimes = ObservableScheduleTimes(), create: @escaping () -> Observable<Element>) -> ScheduledObservable<Element> {
        var source: Observable<Element>?
        var subscription: Disposable?
        let observer = createObserver(Element.self)

        _ = scheduleAbsoluteVirtual((), time: time.createTime) {
            source = create()
            return Disposables.create()
        }

        _ = scheduleAbsoluteVirtual((), time: time.subscribeTime) {
            subscription = source!.subscribe(observer)
            return Disposables.create()
        }

        _ = scheduleAbsoluteVirtual((), time: time.disposeTime) {
            subscription!.dispose()
            return Disposables.create()
        }

        return ScheduledObservable(observer: observer, time: time)
    }
}

struct ScheduledObservable<Element> {
    let observer: TestableObserver<Element>
    let time: ObservableScheduleTimes

    var createTime: Int {
        return time.createTime
    }

    var subscribeTime: Int {
        return time.subscribeTime
    }

    var disposeTime: Int {
        return time.disposeTime
    }

    var events: [Recorded<Event<Element>>] {
        return observer.events
    }
}

struct ObservableScheduleTimes {
    let createTime: Int
    let subscribeTime: Int
    let disposeTime: Int

    init(createTime: Int, subscribeTime: Int, disposeTime: Int) {
        self.createTime = createTime
        self.subscribeTime = subscribeTime
        self.disposeTime = disposeTime
    }

    init() {
        createTime = TestScheduler.Defaults.created
        subscribeTime = TestScheduler.Defaults.subscribed
        disposeTime = TestScheduler.Defaults.disposed
    }
}

extension ObservableScheduleTimes {
    var before: ObservableScheduleTimes {
        return ObservableScheduleTimes(createTime: createTime - 1,
                                       subscribeTime: subscribeTime - 1,
                                       disposeTime: disposeTime - 1)
    }

    var after: ObservableScheduleTimes {
        return ObservableScheduleTimes(createTime: createTime + 1,
                                       subscribeTime: subscribeTime + 1,
                                       disposeTime: disposeTime + 1)
    }
}

extension BluetoothError {
    static var invalidStateErrors: [(CBManagerState, _BluetoothError)] {
        return [
            (.poweredOff, .bluetoothPoweredOff),
            (.resetting, .bluetoothResetting),
            (.unauthorized, .bluetoothUnauthorized),
            (.unknown, .bluetoothInUnknownState),
            (.unsupported, .bluetoothUnsupported),
        ]
    }
}
