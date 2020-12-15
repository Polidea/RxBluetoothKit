import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class PeripheralUpdateViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var peripheralUpdateView = PeripheralUpdateView()

    override func loadView() {
        view = peripheralUpdateView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpdate(enabled: false)
        peripheralUpdateView.advertiseButton.addTarget(self, action: #selector(handleAdvertiseButton), for: .touchUpInside)
        peripheralUpdateView.updateValueButton.addTarget(self, action: #selector(handleUpdateValueButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = PeripheralManager()
    private var characteristic: CBMutableCharacteristic?
    private var advertisement: Disposable?
    private var isAdvertising = false {
        didSet {
            let text = isAdvertising ? "Stop Advertising" : "Advertise"
            peripheralUpdateView.advertiseButton.setTitle(text, for: .normal)

            setUpdate(enabled: isAdvertising)
        }
    }

    @objc private func handleAdvertiseButton() {
        isAdvertising ? handleAdvertisingStop() : handleAdvertisingStart()
    }

    @objc private func handleUpdateValueButton() {
        guard let value = peripheralUpdateView.valueTextField.text,
              let data = value.data(using: .utf8),
              let characteristic = self.characteristic else { return }

        let updated = manager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        if !updated {
            AlertPresenter.presentError(with: "Updating error", on: navigationController)
        }
    }

    private func handleAdvertisingStart() {
        guard let serviceUuidString = peripheralUpdateView.serviceUuidTextField.text,
              let characteristicUuidString = peripheralUpdateView.characteristicUuidTextField.text,
              let value = peripheralUpdateView.valueTextField.text else { return }

        let service = createService(uuidString: serviceUuidString)
        let characteristic = createCharacteristic(uuidString: characteristicUuidString, value: value)
        service.characteristics = [characteristic]

        startAdvertising(service: service)
        self.characteristic = characteristic
    }

    private func handleAdvertisingStop() {
        advertisement?.dispose()
        advertisement = nil
        characteristic = nil
        isAdvertising.toggle()
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

        advertisement = Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.add(service) }
            .flatMap { [manager] in manager.startAdvertising($0.advertisingData) }
            .subscribe(
                onNext: { [weak self] in
                    print("advertising started! \($0)")
                    self?.isAdvertising.toggle()
                },
                onError: { [weak self] in
                    AlertPresenter.presentError(with: $0.printable, on: self?.navigationController)
                }
            )
    }

    private func setUpdate(enabled: Bool) {
        peripheralUpdateView.valueTextField.isEnabled = enabled
        peripheralUpdateView.updateValueButton.isEnabled = enabled
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
