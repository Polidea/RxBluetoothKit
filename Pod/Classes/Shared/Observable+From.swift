//
//  Observable+From.swift
//  Pods
//
//  Created by Przemysław Lenart on 09/03/16.
//
//

import Foundation
import RxSwift

class ArrayObserverProxy<Element>: ObserverType {
    let toObserver: AnyObserver<Element>

    init(toObserver: AnyObserver<Element>) {
        self.toObserver = toObserver
    }

    func on(event: Event<[Element]>) {
        switch event {
        case .Next(let elements):
            for e in elements {
                toObserver.onNext(e)
            }
        case .Error(let error):
            toObserver.onError(error)
        case .Completed:
            toObserver.onCompleted()
        }
    }
}

class FromArrayObservable<Element>: ObservableType {
    typealias E = Element

    let source: Observable<[Element]>
    init(source: Observable<[Element]>) {
        self.source = source
    }

    func subscribe<O: ObserverType where O.E == E>(observer: O) -> Disposable {
        let proxy = ArrayObserverProxy(toObserver: observer.asObserver())
        return source.subscribe(proxy)
    }
}

extension ObservableType {
    // swiftlint:disable missing_docs
    /**
     Converts array event from source observable to an observable which emits its elements.

    - parameter queue: Observable which emits array objects
    - returns: New observable which emits elements from array individually from source observable.
    */
    @warn_unused_result(message="http://git.io/rxs.uo")
    public static func from(arrayObservable: Observable<[E]>) -> Observable<E> {
        return FromArrayObservable(source: arrayObservable).asObservable()
    }
    // swiftlint:enable missing_docs
}
