import Foundation
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

class _CharacteristicNotificationManager {

    private unowned let peripheral: CBPeripheralMock
    private let delegateWrapper: CBPeripheralDelegateWrapperMock
    private var uuidToActiveObservableMap: [CBUUID: Observable<_Characteristic>] = [:]
    private var uuidToActiveObservablesCountMap: [CBUUID: Int] = [:]
    private let lock = NSLock()

    init(peripheral: CBPeripheralMock, delegateWrapper: CBPeripheralDelegateWrapperMock) {
        self.peripheral = peripheral
        self.delegateWrapper = delegateWrapper
    }

    func observeValueUpdateAndSetNotification(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
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

    private func setNotifyValue(_ enabled: Bool, for characteristic: _Characteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic.characteristic)
    }
}
