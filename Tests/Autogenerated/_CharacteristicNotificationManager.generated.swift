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
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

class _CharacteristicNotificationManager {

    private unowned let peripheral: CBPeripheralMock
    private let delegateWrapper: CBPeripheralDelegateWrapperMock
    private var uuidToActiveObservableMap: [CBUUID: Observable<_Characteristic>] = [:]
    private let lock = NSLock()

    init(peripheral: CBPeripheralMock, delegateWrapper: CBPeripheralDelegateWrapperMock) {
        self.peripheral = peripheral
        self.delegateWrapper = delegateWrapper
    }

    func observeValueUpdateAndSetNotification(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }

            if let activeObservable = strongSelf.uuidToActiveObservableMap[characteristic.uuid] {
                return activeObservable
            }

            let notifyValue = strongSelf.setNotifyValue(true, for: characteristic).asObservable()
            let notificationObserable = strongSelf.createValueUpdateObservable(for: characteristic)
            let observable = Observable.of(notifyValue, notificationObserable)
                .merge()
                .do(onDispose: { [weak self] in
                    guard let strongSelf = self else { return }
                    do { strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                        strongSelf.uuidToActiveObservableMap.removeValue(forKey: characteristic.uuid)
                    }
                    _ = strongSelf.setNotifyValue(false, for: characteristic)
                        .subscribe()
                })
                .share()
            strongSelf.uuidToActiveObservableMap[characteristic.uuid] = observable
            return observable
        }
    }

    private func createValueUpdateObservable(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        return delegateWrapper
            .peripheralDidUpdateValueForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .map { (_, error) -> _Characteristic in
                if let error = error {
                    throw _BluetoothError.characteristicReadFailed(characteristic, error)
                }
                return characteristic
            }
    }

    private func setNotifyValue(_ enabled: Bool, for characteristic: _Characteristic) -> Single<_Characteristic> {
        let observable = delegateWrapper
            .peripheralDidUpdateNotificationStateForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .map { (_, error) -> _Characteristic in
                if let error = error {
                    throw _BluetoothError.characteristicNotifyChangeFailed(characteristic, error)
                }
                return characteristic
        }
        let setObservable: Observable<_Characteristic> = .deferred { [weak self] in
            self?.peripheral.setNotifyValue(enabled, for: characteristic.characteristic)
            return .empty()
        }
        return Observable.of(
            observable,
            setObservable
        ).merge().asSingle()
    }
}
