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

public class PeripheralManager: BluetoothStateProvider {

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
    init(peripheralManager: CBPeripheralManager) {
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
        self.init(peripheralManager: CBPeripheralManager(delegate: nil, queue: queue, options: options))
    }

    // MARK: State

    /// Current state of `PeripheralManager` instance described by `BluetoothState` which is equivalent to [CBManagerState](https://developer.apple.com/reference/corebluetooth/cbmanager/1648600-state).
    /// - returns: Current state of `PeripheralManager` as `BluetoothState`.
    public var state: BluetoothState {
        return BluetoothState(rawValue: peripheralManager.state.rawValue) ?? .unsupported
    }

    /// Observable which emits next whenever state of `CentralManager` changes. Never completes and errors
    public var stateChanges: Observable<BluetoothState> {
        return delegateWrapper.rx_didUpdateState
    }

    public typealias AdvertisingStarted = Void
    //TODO: Docs
    public func startAdvertising(_ advertisementData: Variable<[String : Any]?>) -> Single<AdvertisingStarted> {
        let observable = Observable<AdvertisingStarted>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(BluetoothError.destroyed)
                return Disposables.create()
            }
            if strongSelf.isAdvertising {
                observer.onError(BluetoothError.peripheralAlreadyAdvertising)
                return Disposables.create()
            }
            let disposable = strongSelf.delegateWrapper.rx_didStartAdvertising
                .flatMap { error -> Observable<AdvertisingStarted> in
                    if let error = error {
                        throw BluetoothError.peripheralAdvertisingFailed(error)
                    }
                    return .just(())
            }.subscribe(observer)
            let advertisementChangesDisposable = advertisementData
                .asObservable()
                .subscribe(onNext: { [weak self] advertisement in
                    self?.peripheralManager.startAdvertising(advertisement)
                })

            return Disposables.create { [weak self] in
                disposable.dispose()
                advertisementChangesDisposable.dispose()
                self?.peripheralManager.stopAdvertising()
            }
        }
        return ensure(state: .poweredOn, for: observable).asSingle()
    }

    public func startAdvertising(_ advertisementData: [String : Any]?) -> Single<AdvertisingStarted> {
        return startAdvertising(Variable(advertisementData))
    }
}
