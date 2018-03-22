import CoreBluetooth
import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    // MARK: - Public outputs
    var dataUpdateOutput: Observable<Void> {
        return characteristicUpdateTrigger.asObservable()
    }

    var characteristicsOutput: Observable<Characteristic> {
        return discoveredCharacteristicsSubject.asObservable()
    }

    var characteristicWriteOutput: Observable<Result<Characteristic, Error>> {
        return bluetoothService.writeValueOutput
    }

    var characteristicReadOutput: Observable<Result<Characteristic, Error>> {
        return bluetoothService.readValueOutput
    }

    // MARK: - Private fields
    private let disposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService

    private let selectedService: Service

    private let selectedPeripheral: Peripheral

    private let discoveredCharacteristicsSubject = PublishSubject<Characteristic>()

    private let characteristicUpdateTrigger = PublishSubject<Void>()

    private var notificationDisposables: [Characteristic: Disposable] = [:]

    weak private var selectedCharacteristic: Characteristic?

    // MARK: - Initialization
    init(with bluetoothService: RxBluetoothKitService, service: Service, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.selectedService = service
        self.selectedPeripheral = peripheral
        self.bindCharacteristicsOutput()
    }

    // MARK: - Public methods

// Method used to pass the characteristic selected by the user and to be able to perform further operations on it
    func setSelected(characteristic: Characteristic) {
        self.selectedCharacteristic = characteristic
    }

    // Triggers reading value from the selected characteristic
    func triggerValueRead() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        bluetoothService.readValueFrom(characteristic)
    }

    // Performs writing operation to selected characteristic
    func writeToCharacteristic(value: String) {
        guard let characteristic = selectedCharacteristic,
              let writeType = characteristic.determineWriteType() else {
            return
        }

        let hexadecimalData: Data = Data.fromHexString(string: value)
        bluetoothService.writeValueTo(characteristic: characteristic, data: hexadecimalData)
    }

    // If user sets notification on for the selected characteristic, we subscribe for notifications, otherwise
    // we dispose the disposable that was created with prior subscription and we remove that disposable for our
    // notificationDisposables dicitonary
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

    // Discovered characteristic is being bound to it's subject, we catch the .error event and pass it to alertTrigger
    // so it can be easily consumed by the view controller.
    private func bindCharacteristicsOutput() {
        bluetoothService.discoverCharacteristics(for: selectedService).subscribe(onNext: { [unowned self] characteristics in
            characteristics.forEach { characteristic in
                self.discoveredCharacteristicsSubject.onNext(characteristic)
            }
        }, onError: { [unowned self] error in
//            let result = AlertResult.error(error)
//            self.alertTrigger.onNext(result)
        }).disposed(by: disposeBag)
    }

    private func subscribeForNotifications() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        let disposable = observeValueUpdateAndSetNotification(for: characteristic)
        observeNotifyValue(characteristic: characteristic)
        notificationDisposables[characteristic] = disposable
    }

    // observeValueUpdateAndSetNotification(:_) returns a disposable from subscription, which triggers notifying start
    // on a selected characteristic.
    private func observeValueUpdateAndSetNotification(for characteristic: Characteristic) -> Disposable {
        return characteristic.observeValueUpdateAndSetNotification()
                .subscribe(onNext: { [weak self] (characteristic) in
                    self?.characteristicUpdateTrigger.onNext(Void())
                }, onError: { [weak self] (error) in
//                    let result = AlertResult.error(error)
//                    self?.alertTrigger.onNext(result)
                })
    }

    // observeNotifyValue tells us when exactly a characteristic has changed it's state (e.g isNotifying).
    // We need to use this method, because hardware needs an amount of time to switch characteristic's state.
    private func observeNotifyValue(characteristic: Characteristic) {
        selectedPeripheral.observeNotifyValue(for: characteristic)
                .subscribe(onNext: { [weak self] tuple in
                    self?.characteristicUpdateTrigger.onNext(Void())
                }, onError: { [unowned self] error in
//                    let result = AlertResult.error(error)
//                    self.alertTrigger.onNext(result)
                }).disposed(by: disposeBag)
    }
}
