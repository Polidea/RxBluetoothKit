import CoreBluetooth
import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    var characteristicsOutput: Observable<[Characteristic]> {
        return bluetoothService.discoverCharacteristics(for: service)
    }

    private let disposeBag: DisposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService

    private var characteristic: Characteristic?

    private let service: Service

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
        characteristic.readValue().subscribe(onSuccess: { char in
            print(char.value)
        }, onError: { error in
            print(error)
        }).disposed(by: disposeBag)
    }

    func writeValueForCharacteristic(hexadecimalString: String) {
        guard let characteristic = characteristic else {
            return
        }
        let hexadecimalData: Data = Data.fromHexString(string: hexadecimalString)
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        characteristic.writeValue(hexadecimalData as Data, type: type)
                .subscribe({ _ in
                    print("I wrote sth")
                }).disposed(by: disposeBag)
    }

    func setNotificationsState(enabled: Bool) {
          if enabled {
              subscribeNotification()
          } else {
              notificationsDisposable?.dispose()
          }
    }

    private func subscribeNotification() {
        guard let characteristic = characteristic else {
            return
        }

        notificationsDisposable = characteristic.observeValueUpdateAndSetNotification(for: characteristic)
                .subscribe(onNext: { characteristic in
                    print(characteristic.isNotifying)
                })
    }
}
