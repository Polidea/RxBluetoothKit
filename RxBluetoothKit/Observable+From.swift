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
