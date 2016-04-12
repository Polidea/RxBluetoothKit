//
//  Observable+Absorb.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 23/03/16.
//
//

import RxSwift

extension ObservableType {
    // swiftlint:disable missing_docs
    /**
     Absorbes all of events from a and b observables into result observable.

     - parameter a: First observable
     - parameter b: Second observable
     - returns: New observable which emits all of events from a and b observables. If error or complete is received on any of the observables, it's propagates immediately to result observable
     */
    @warn_unused_result(message="http://git.io/rxs.uo")
    public static func absorb(a: Observable<E>, _ b: Observable<E>) -> Observable<E> {
        return Observable.create { observer in
            let disposableBox = MutableBox<CompositeDisposable>()
            let innerObserver: AnyObserver<E> = AnyObserver.init { event in
                observer.on(event)
                if event.isStopEvent {
                    disposableBox.value?.dispose()
                }
            }

            let disposableA = a.subscribe(innerObserver)
            let disposableB = b.subscribe(innerObserver)
            let disposable = CompositeDisposable(disposableA, disposableB)
            disposableBox.value = disposable
            return disposable
        }
    }
}