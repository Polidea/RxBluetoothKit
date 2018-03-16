import CoreBluetooth
import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    var dataUpdateOutput: Observable<Void> {
        return characteristicUpdateTrigger.asObservable()
    }

    var alertTriggerOutput: Observable<String> {
        return alertTrigger.asObservable()
    }

    var characteristicsOutput: Observable<Characteristic> {
        return discoveredCharacteristicsSubject.asObservable()
    }

    private let disposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService

    private let selectedService: Service

    private let selectedPeripheral: Peripheral

    private let discoveredCharacteristicsSubject = PublishSubject<Characteristic>()

    private let characteristicUpdateTrigger = PublishSubject<Void>()

    private let alertTrigger = PublishSubject<String>()

    weak private var selectedCharacteristic: Characteristic?

    private var notificationDisposables: [Characteristic: Disposable] = [:]


    init(with bluetoothService: RxBluetoothKitService, service: Service, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.selectedService = service
        self.selectedPeripheral = peripheral
        self.bindCharacteristicsOutput()
    }

    func setSelected(characteristic: Characteristic) {
        self.selectedCharacteristic = characteristic
    }

    func triggerValueRead() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        characteristic.readValue().subscribe(onSuccess: { [unowned self] char in
            self.characteristicUpdateTrigger.onNext(Void())
        }, onError: { error in
            self.alertTrigger.onNext(error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    func writeValueForCharacteristic(hexadecimalString: String) {
        guard let characteristic = selectedCharacteristic else {
            return
        }
        let hexadecimalData: Data = Data.fromHexString(string: hexadecimalString)
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        characteristic.writeValue(hexadecimalData as Data, type: type)
                .subscribe({ [unowned self] _ in
                    let message = "Wrote \(hexadecimalString) to characteristic: \(characteristic.uuid.uuidString)"
                    self.alertTrigger.onNext(message)
                }).disposed(by: disposeBag)
    }

    func setNotificationsState(enabled: Bool) {
        if enabled {
            subscribeForNotifications()
        } else {
            guard let characteristic = selectedCharacteristic,
                  let disposable = notificationDisposables[characteristic] else {
                return
            }
            disposable.dispose()
            notificationDisposables[characteristic] = nil
            characteristicUpdateTrigger.onNext(Void())
        }
    }

    private func bindCharacteristicsOutput() {
        bluetoothService.discoverCharacteristics(for: selectedService).subscribe(onNext: { [unowned self] characteristics in
            characteristics.forEach { characteristic in
                self.discoveredCharacteristicsSubject.onNext(characteristic)
            }
        }, onError: { error in
            self.alertTrigger.onNext(error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    private func subscribeForNotifications() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        let disposable = observeValueUpdateAndSetNotification(for: characteristic)
        observeCharacteristicsStateChanged(characteristic: characteristic)
        notificationDisposables[characteristic] = disposable
    }

    private func observeValueUpdateAndSetNotification(for characteristic: Characteristic) -> Disposable {
        return characteristic.observeValueUpdateAndSetNotification()
                .subscribe(onNext: { [weak self] (characteristic) in
                    self?.characteristicUpdateTrigger.onNext(Void())
                }, onError: { [weak self] (error) in
                    self?.alertTrigger.onNext(error.localizedDescription)
                })
    }

    private func observeCharacteristicsStateChanged(characteristic: Characteristic) {
        selectedPeripheral.observeCharacteristicStateChanged(for: characteristic)
                .subscribe(onNext: { [weak self] tuple in
                    self?.characteristicUpdateTrigger.onNext(Void())
                }, onError: { [weak self] error in
                    self?.alertTrigger.onNext(error.localizedDescription)
                }).disposed(by: disposeBag)
    }
}
