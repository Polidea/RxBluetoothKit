import CoreBluetooth
import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    // MARK: - Public outputs

    var characteristicsOutput: Observable<Result<Characteristic, Error>> {
        return discoveredCharacteristicsSubject
    }

    var characteristicWriteOutput: Observable<Result<Characteristic, Error>> {
        return bluetoothService.writeValueOutput
    }

    var characteristicReadOutput: Observable<Result<Characteristic, Error>> {
        return bluetoothService.readValueOutput
    }

    var updatedValueAndNotificationOutput: Observable<Result<Characteristic, Error>> {
        return bluetoothService.updatedValueAndNotificationOutput
    }

    // MARK: - Private fields

    weak private var selectedCharacteristic: Characteristic?

    private let bluetoothService: RxBluetoothKitService

    private let selectedService: Service

    private let selectedPeripheral: Peripheral

    private let discoveredCharacteristicsSubject = PublishSubject<Result<Characteristic, Error>>()

    private let characteristicUpdateTrigger = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

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
        guard let characteristic = selectedCharacteristic else {
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
            guard let characteristic = selectedCharacteristic else { return }
            bluetoothService.disposeNotification(for: characteristic)
        }
    }

    // Discovered characteristic is being bound to it's subject, we catch the .error event and pass it to alertTrigger
    // so it can be easily consumed by the view controller.
    private func bindCharacteristicsOutput() {
        bluetoothService.discoverCharacteristics(for: selectedService)
        bluetoothService.discoveredCharacteristicsOutput.subscribe(onNext: { [unowned self] result in
            switch result {
            case .success(let characteristics):
                characteristics.forEach { characteristic in
                    self.discoveredCharacteristicsSubject.onNext(Result.success(characteristic))
                }
            case .error(let error):
                self.discoveredCharacteristicsSubject.onNext(Result.error(error))
            }
        }).disposed(by: disposeBag)
    }

    private func subscribeForNotifications() {
        guard let characteristic = selectedCharacteristic else {
            return
        }

        bluetoothService.observeValueUpdateAndSetNotification(for: characteristic)
        bluetoothService.observeNotifyValue(peripheral: selectedPeripheral, characteristic: characteristic)
    }
}
