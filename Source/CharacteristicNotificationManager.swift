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
            guard let self = self else { throw BluetoothError.destroyed }
            self.lock.lock(); defer { self.lock.unlock()}

            if let activeObservable = self.uuidToActiveObservableMap[characteristic.uuid] {
                return activeObservable
            }

            let notificationObserable = self.createValueUpdateObservable(for: characteristic)
            let observable = notificationObserable
                .do(onSubscribed: { [weak self] in
                    guard let self = self else { return }
                    self.lock.lock(); defer { self.lock.unlock() }
                    let counter = self.uuidToActiveObservablesCountMap[characteristic.uuid] ?? 0
                    self.uuidToActiveObservablesCountMap[characteristic.uuid] = counter + 1
                    self?.setNotifyValue(true, for: characteristic)
                }, onDispose: { [weak self] in
                    guard let self = self else { return }
                    self.lock.lock(); defer { self.lock.unlock() }
                    let counter = self.uuidToActiveObservablesCountMap[characteristic.uuid] ?? 1
                    self.uuidToActiveObservablesCountMap[characteristic.uuid] = counter - 1

                    if counter <= 1 {
                        self.uuidToActiveObservableMap.removeValue(forKey: characteristic.uuid)
                        self.setNotifyValue(false, for: characteristic)
                    }
                })
                .share()

            self.uuidToActiveObservableMap[characteristic.uuid] = observable
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
