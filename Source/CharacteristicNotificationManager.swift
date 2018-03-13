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
import RxSwift

class CharacteristicNotificationManager {

    private unowned let peripheral: CBPeripheral
    private let delegateWrapper: CBPeripheralDelegateWrapper
    private var uuidToActiveObservableMap: [CBUUID: Observable<Characteristic>] = [:]
    private var uuidToActiveObservablesCountMap: [CBUUID: Int] = [:]
    private let lock = NSLock()

    init(peripheral: CBPeripheral, delegateWrapper: CBPeripheralDelegateWrapper) {
        self.peripheral = peripheral
        self.delegateWrapper = delegateWrapper
    }

    func observeValueUpdateAndSetNotification(for characteristic: Characteristic) -> Observable<Characteristic> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw BluetoothError.destroyed }
            strongSelf.lock.lock(); defer { strongSelf.lock.unlock()}

            if let activeObservable = strongSelf.uuidToActiveObservableMap[characteristic.uuid] {
                return activeObservable
            }

            let notificationObserable = strongSelf.createValueUpdateObservable(for: characteristic)
            let observable = notificationObserable
                .do(onSubscribed: { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                    let counter = strongSelf.uuidToActiveObservablesCountMap[characteristic.uuid] ?? 0
                    strongSelf.uuidToActiveObservablesCountMap[characteristic.uuid] = counter + 1
                    self?.setNotifyValue(true, for: characteristic)
                }, onDispose: { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                    let counter = strongSelf.uuidToActiveObservablesCountMap[characteristic.uuid] ?? 1
                    strongSelf.uuidToActiveObservablesCountMap[characteristic.uuid] = counter - 1

                    if counter <= 1 {
                        strongSelf.uuidToActiveObservableMap.removeValue(forKey: characteristic.uuid)
                        strongSelf.setNotifyValue(false, for: characteristic)
                    }
                })
                .share()

            strongSelf.uuidToActiveObservableMap[characteristic.uuid] = observable
            return observable
        }
    }

    private func createValueUpdateObservable(for characteristic: Characteristic) -> Observable<Characteristic> {
        return delegateWrapper
            .peripheralDidUpdateValueForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .map { (_, error) -> Characteristic in
                if let error = error {
                    throw BluetoothError.characteristicReadFailed(characteristic, error)
                }
                return characteristic
            }
    }

    private func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic.characteristic)
    }
}
