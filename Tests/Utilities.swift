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

enum TestError: Error {
    case error
}

func XCTAssertError<ErrorType: Equatable, Element>(_ event: Event<Element>, _ errorType: ErrorType, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(event.isStopEvent, message, file: file, line: line)
    XCTAssertNotNil(event.error, message, file: file, line: line)
    XCTAssertTrue(event.error is ErrorType, message, file: file, line: line)
    XCTAssertEqual(event.error as? ErrorType, errorType, message, file: file, line: line)
}

func createEventRecords<T>(records: (Int, Event<T>)...) -> [Recorded<Event<T>>] {
    var array = [Recorded<Event<T>>]()
    for (time, event) in records {
        array.append(Recorded(time: time, value: event))
    }
    return array
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

extension _BluetoothError {
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

extension RxError: Equatable {}

public func ==(lhs: RxError, rhs: RxError) -> Bool {
    switch(lhs, rhs) {
    case (.unknown, .unknown): return true
    case (.overflow, .overflow): return true
    case (.argumentOutOfRange, .argumentOutOfRange): return true
    case (.noElements, .noElements): return true
    case (.moreThanOneElement, .moreThanOneElement): return true
    case (.timeout, .timeout): return true
    default:
        return false
    }
}
