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

public class PeripheralManager {

    public let peripheralManager: CBPeripheralManager

    private let delegateWrapper = CBPeripheralManagerDelegateWrapper()

    /// IndicatesWhether or not the peripheral is currently advertising data.
    public var isAdvertising: Bool {
        return peripheralManager.isAdvertising
    }

    /// This method does not prompt the user for access.
    /// You can use it to detect restricted access and simply hide UI instead of prompting for access.
    /// - returns: The current authorization status for sharing data while backgrounded.
    public class func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus {
        return CBPeripheralManager.authorizationStatus()
    }

    // MARK: Initialization

    /// Creates new `PeripheralManager`
    /// - parameter peripheralManager: CBPeripheralManager instance used to perform peripheral mode operations
    /// - parameter queueScheduler: Scheduler on which all serialised operations are executed (such as scans). By default main thread is used.
    init(peripheralManager: CBPeripheralManager,
         queueScheduler: SchedulerType = ConcurrentMainScheduler.instance) {
        self.peripheralManager = peripheralManager
        peripheralManager.delegate = delegateWrapper
    }

    /// Creates new `PeripheralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Peripheral Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheralManager_Class/index.html)
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: Any]? = nil) {
        self.init(peripheralManager: CBPeripheralManager(delegate: nil, queue: queue, options: options),
                  queueScheduler: ConcurrentDispatchQueueScheduler(queue: queue))
    }

    // MARK: State

    /// Continuous state of `PeripheralManager` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Observable that emits `Next` immediately after subscribtion with current state of Bluetooth. Later,
    /// whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
    public var rx_state: Observable<BluetoothState> {
        return .deferred { [weak self] in
            guard let `self` = self else { throw BluetoothError.destroyed }
            return self.delegateWrapper.rx_didUpdateState.startWith(self.state)
        }
    }

    /// Current state of `CentralManager` instance described by `BluetoothState` which is equivalent to [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Current state of `PeripheralManager` as `BluetoothState`.
    public var state: BluetoothState {
        return BluetoothState(rawValue: peripheralManager.state.rawValue) ?? .unsupported
    }

    private var isWaitingForAdvertisingCompletion = false
    public typealias AdvertisingStarted = Void
    //TODO: Docs
    public func startAdvertising(_ advertisementData: [String : Any]?) -> Observable<AdvertisingStarted> {
        return Observable.deferred {
            
        }
    }
}
