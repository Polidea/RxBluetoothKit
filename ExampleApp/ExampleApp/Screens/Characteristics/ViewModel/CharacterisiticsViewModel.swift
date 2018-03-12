import CoreBluetooth
import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    var characteristicsOutput: Observable<[Characteristic]> {
        return bluetoothService.discoverCharacteristics(for: service)
    }

    var dataUpdateOutput: Observable<Void> {
        return characteristicUpdateTrigger.asObservable()
    }

    var alertTriggerOutput: Observable<String> {
        return alertTrigger.asObservable()
    }

    private let disposeBag: DisposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService

    private let service: Service

    private let characteristicUpdateTrigger: PublishSubject<Void> = PublishSubject()

    private let alertTrigger: PublishSubject<String> = PublishSubject()

    private var characteristic: Characteristic?

    private var notificationsDisposable: Disposable?

    init(with bluetoothService: RxBluetoothKitService, service: Service) {
        self.bluetoothService = bluetoothService
        self.service = service
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
