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

    private let disposeBag: DisposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService

    private let service: Service

    private let discoveredCharacteristicsSubject: PublishSubject<Characteristic> = PublishSubject()

    private let characteristicUpdateTrigger: PublishSubject<Void> = PublishSubject()

    private let alertTrigger: PublishSubject<String> = PublishSubject()

    private var characteristic: Characteristic?

    private var notificationsDisposable: Disposable?

    init(with bluetoothService: RxBluetoothKitService, service: Service) {
        self.bluetoothService = bluetoothService
        self.service = service
        self.bindCharacteristicsOutput()
    }

    func setCurrent(characteristic: Characteristic) {
        self.characteristic = characteristic
    }

    func triggerValueRead() {
        guard let characteristic = characteristic else {
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
        guard let characteristic = characteristic else {
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
        guard let characteristic = characteristic else {
            return
        }

        notificationsDisposable = characteristic.observeValueUpdateAndSetNotification(for: characteristic)
                .subscribe({ [weak self] _ in
                    self?.characteristicUpdateTrigger.onNext(Void())
                })
    }
}
