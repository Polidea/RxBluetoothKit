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
import RxSwift

/// Closure that receives `RestoredState` as a parameter
public typealias OnWillRestoreState = (RestoredState) -> Void

extension CentralManager {

    convenience init(queue: DispatchQueue = .main,
                     options: [String: AnyObject]? = nil,
                     onWillRestoreState: OnWillRestoreState? = nil) {
        self.init(queue: queue, options: options)
        if let onWillRestoreState = onWillRestoreState {
            listenOnWillRestoreState(onWillRestoreState)
        }
    }

    /// Emits `RestoredState` instance, when state of `CentralManager` has been restored,
    /// Should only be called once in the lifetime of the app
    /// - returns: Observable which emits next events state has been restored
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreState) {
        _ = delegateWrapper
            .willRestoreState
            .take(1)
            .flatMap { [weak self] dict -> Observable<RestoredState> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return .just(RestoredState(restoredStateDictionary: dict, centralManager: strongSelf))
            }
            .subscribe(onNext: { handler($0) })
    }
}
