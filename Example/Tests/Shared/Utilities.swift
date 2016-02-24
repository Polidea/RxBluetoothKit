//
//  HelperFunctions.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 25.02.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RxTests
import RxSwift
import CoreBluetooth
import RxBluetoothKit

//Helps
final class Box<T> {
    let value: T
    
    init(value: T) {
        self.value = value
    }
}

func expectError<ErrorType : Equatable, Element>(event: Event<Element>, errorType: ErrorType, file: String = __FILE__, line: UInt = __LINE__) {
    expect(event.isStopEvent, file: file, line: line).to(beTrue())
    expect(event.error, file: file, line: line).toNot(beNil())
    expect(event.error is ErrorType, file: file, line: line).to(beTrue())
    expect(event.error as? ErrorType, file: file, line: line).to(equal(errorType))
}

extension TestScheduler {
    func scheduleObservable<Element>(time: ObservableScheduleTimes = ObservableScheduleTimes(), create: () -> Observable<Element>) -> ScheduledObservable<Element> {
        var source : Observable<Element>? = nil
        var subscription : Disposable? = nil
        let observer = createObserver(Element)
        
        self.scheduleAbsoluteVirtual((), time: time.createTime) {
            source = create()
            return NopDisposable.instance
        }
        
        self.scheduleAbsoluteVirtual((), time: time.subscribeTime) {
            subscription = source!.subscribe(observer)
            return NopDisposable.instance
        }
        
        self.scheduleAbsoluteVirtual((), time: time.disposeTime) {
            subscription!.dispose()
            return NopDisposable.instance
        }
        
        return ScheduledObservable(observer: observer, time: time)
    }
}

struct ScheduledObservable<Element> {
    let observer : TestableObserver<Element>
    let time : ObservableScheduleTimes
    
    var createTime : Int {
        return time.createTime
    }
    
    var subscribeTime : Int {
        return time.subscribeTime
    }
    
    var disposeTime : Int {
        return time.disposeTime
    }
    
    var events : [Recorded<Event<Element>>] {
        return observer.events
    }
}

struct ObservableScheduleTimes {
    let createTime : Int
    let subscribeTime : Int
    let disposeTime : Int
    
    init(createTime: Int, subscribeTime: Int, disposeTime: Int) {
        self.createTime = createTime
        self.subscribeTime = subscribeTime
        self.disposeTime = disposeTime
    }
    
    init() {
        self.createTime = TestScheduler.Defaults.created
        self.subscribeTime = TestScheduler.Defaults.subscribed
        self.disposeTime = TestScheduler.Defaults.disposed
    }
}

extension ObservableScheduleTimes {
    var before : ObservableScheduleTimes {
        return ObservableScheduleTimes(createTime: createTime - 1,
                                       subscribeTime: subscribeTime - 1,
                                       disposeTime: disposeTime - 1)
    }
    
    var after : ObservableScheduleTimes {
        return ObservableScheduleTimes(createTime: createTime + 1,
                                       subscribeTime: subscribeTime + 1,
                                       disposeTime: disposeTime + 1)
    }
}

extension BluetoothError {
    static var invalidStateErrors : [(CBCentralManagerState, BluetoothError)] {
        return [(.PoweredOff,   .BluetoothPoweredOff),
                (.Resetting,    .BluetoothResetting),
                (.Unauthorized, .BluetoothUnauthorized),
                (.Unknown,      .BluetoothInUnknownState),
                (.Unsupported,  .BluetoothUnsupported)]
    }
}
