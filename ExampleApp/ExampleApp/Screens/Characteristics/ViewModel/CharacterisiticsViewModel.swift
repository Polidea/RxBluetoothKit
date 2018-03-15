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

    private let service: Service

    private var selectedCharacteristic: Characteristic?

    private let discoveredCharacteristicsSubject = PublishSubject<Characteristic>()

    private let characteristicUpdateTrigger = PublishSubject<Void>()

    private let alertTrigger = PublishSubject<String>()

    private var notificationDisposables: [Characteristic: Disposable] = [:]

    private var notificationsDisposable: Disposable?

    init(with bluetoothService: RxBluetoothKitService, service: Service) {
        self.bluetoothService = bluetoothService
        self.service = service
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
            let message = error.localizedDescription
            self.alertTrigger.onNext(message)
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
            subscribeNotification()
        } else {
            notificationsDisposable?.dispose()
            characteristicUpdateTrigger.onNext(Void())
        }
    }

    private func bindCharacteristicsOutput() {
        bluetoothService.discoverCharacteristics(for: service).subscribe(onNext: { [unowned self] characteristics in
            characteristics.forEach { characteristic in
                self.discoveredCharacteristicsSubject.onNext(characteristic)
            }
        }, onError: { error in
            let message = error.localizedDescription
            self.alertTrigger.onNext(message)
        }).disposed(by: disposeBag)
    }

    private func subscribeNotification() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        notificationsDisposable = characteristic.observeValueUpdateAndSetNotification()
                .subscribe({ [weak self] _ in
                    self?.characteristicUpdateTrigger.onNext(Void())
                })
    }
}
