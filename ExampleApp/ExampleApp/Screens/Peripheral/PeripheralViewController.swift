import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class PeripheralViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var peripheralView = PeripheralView()

    override func loadView() {
        view = peripheralView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralView.advertiseButton.addTarget(self, action: #selector(handleAdvertiseButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = PeripheralManager()

    @objc private func handleAdvertiseButton() {
        guard let serviceUuidString = peripheralView.serviceUuidTextField.text,
              let characteristicUuidString = peripheralView.characteristicUuidTextField.text,
              let value = peripheralView.valueTextField.text else { return }

        let service = createService(uuidString: serviceUuidString)
        let characteristic = createCharacteristic(uuidString: characteristicUuidString, value: value)
        service.characteristics = [characteristic]

        startAdvertising(service: service)
    }

    private func createService(uuidString: String) -> CBMutableService {
        let serviceUuid = CBUUID(string: uuidString)
        return CBMutableService(type: serviceUuid, primary: true)
    }

    private func createCharacteristic(uuidString: String, value: String) -> CBMutableCharacteristic {
        let characteristicUuid = CBUUID(string: uuidString)
        return CBMutableCharacteristic(
            type: characteristicUuid,
            properties: .read,
            value: value.data(using: .utf8),
            permissions: .readable
        )
    }

    private func startAdvertising(service: CBMutableService) {
        let managerIsOn = manager.observeStateWithInitialValue().debug("state")
            .filter { $0 == .poweredOn }

        Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.add(service) }
            .flatMap { [manager] in manager.startAdvertising($0.advertisingData) }
            .subscribe(onNext: { print("advertising started! \($0)") })
            .disposed(by: disposeBag)
    }

}

extension CBService {

    var advertisingData: [String: Any] {
        [
            CBAdvertisementDataServiceUUIDsKey: [uuid],
            CBAdvertisementDataLocalNameKey: "RxBluetoothKit"
        ]
    }

}
