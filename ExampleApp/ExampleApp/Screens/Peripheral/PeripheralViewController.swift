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

        setUpdate(enabled: false)
        peripheralView.advertiseButton.addTarget(self, action: #selector(handleAdvertiseButton), for: .touchUpInside)
        peripheralView.updateValueButton.addTarget(self, action: #selector(handleUpdateValueButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = PeripheralManager()
    private var characteristic: CBMutableCharacteristic?

    @objc private func handleAdvertiseButton() {
        guard let serviceUuidString = peripheralView.serviceUuidTextField.text,
              let characteristicUuidString = peripheralView.characteristicUuidTextField.text,
              let value = peripheralView.valueTextField.text else { return }

        let service = createService(uuidString: serviceUuidString)
        let characteristic = createCharacteristic(uuidString: characteristicUuidString, value: value)
        service.characteristics = [characteristic]

        startAdvertising(service: service)
        self.characteristic = characteristic
    }

    @objc private func handleUpdateValueButton() {
        guard let value = peripheralView.valueTextField.text,
              let data = value.data(using: .utf8),
              let characteristic = self.characteristic else { return }

        let result = manager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        print("updating value: \(result)")
    }

    private func createService(uuidString: String) -> CBMutableService {
        let serviceUuid = CBUUID(string: uuidString)
        return CBMutableService(type: serviceUuid, primary: true)
    }

    private func createCharacteristic(uuidString: String, value: String) -> CBMutableCharacteristic {
        let characteristicUuid = CBUUID(string: uuidString)
        return CBMutableCharacteristic(
            type: characteristicUuid,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
    }

    private func startAdvertising(service: CBMutableService) {
        let managerIsOn = manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }

        Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.add(service) }
            .flatMap { [manager] in manager.startAdvertising($0.advertisingData) }
            .subscribe(
                onNext: { [weak self] in
                    print("advertising started! \($0)")
                    self?.setUpdate(enabled: true)
                },
                onError: { [weak self] in
                    AlertPresenter.presentError(with: $0.localizedDescription, on: self?.navigationController)
                }
            )
            .disposed(by: disposeBag)
    }

    private func setUpdate(enabled: Bool) {
        peripheralView.valueTextField.isEnabled = enabled
        peripheralView.updateValueButton.isEnabled = enabled
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
