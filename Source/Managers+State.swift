// The MIT License (MIT)
//
// Copyright (c) 2017 Polidea
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
import CoreBluetooth
import RxSwift

public protocol BluetoothStateProvider: class {
    var state: BluetoothState { get }
    var stateChanges: Observable<BluetoothState> { get }
}

extension BluetoothStateProvider {
    /// Continuous state of `CentralManager` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Observable that emits `Next` immediately after subscribtion with current state of Bluetooth. Later,
    /// whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
    public var rx_state: Observable<BluetoothState> {
        return .deferred { [weak self] in
            guard let `self` = self else { throw BluetoothError.destroyed }
            return self.stateChanges.startWith(self.state)
        }
    }

    /// Ensure that `state` is and will be the only state of `CentralManager` during subscription.
    /// Otherwise error is emitted.
    /// - parameter state: `BluetoothState` which should be present during subscription.
    /// - parameter observable: Observable into which potential errors should be merged.
    /// - returns: New observable which merges errors with source observable.
    func ensure<T>(state: BluetoothState, for observable: Observable<T>) -> Observable<T> {
        let statesObservable = rx_state
            .filter { $0 != state && BluetoothError(state: $0) != nil }
            .map { state -> T in throw BluetoothError(state: state)! }
        return .absorb(statesObservable, observable)
    }
}
