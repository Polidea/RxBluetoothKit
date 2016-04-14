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

import RxSwift

extension ObservableType {
    // swiftlint:disable missing_docs
    /**
     Absorbes all of events from a and b observables into result observable.

     - parameter a: First observable
     - parameter b: Second observable
     - returns: New observable which emits all of events from a and b observables.
     If error or complete is received on any of the observables, it's propagates immediately to result observable
     */
    @warn_unused_result(message="http://git.io/rxs.uo")
    static func absorb(a: Observable<E>, _ b: Observable<E>) -> Observable<E> {
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
