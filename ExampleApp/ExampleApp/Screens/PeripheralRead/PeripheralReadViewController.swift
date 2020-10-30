import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class PeripheralReadViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var peripheralReadView = PeripheralReadView()

    override func loadView() {
        view = peripheralReadView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralReadView.advertiseButton.addTarget(self, action: #selector(handleAdvertiseButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = PeripheralManager()
    private var characteristic: CBMutableCharacteristic?
    private var advertisement: Disposable?
    private var isAdvertising = false {
        didSet {
            let text = isAdvertising ? "Stop Advertising" : "Advertise"
            peripheralReadView.advertiseButton.setTitle(text, for: .normal)
        }
    }

    @objc private func handleAdvertiseButton() {
        isAdvertising ? handleAdvertisingStop() : handleAdvertisingStart()
    }

    private func handleAdvertisingStart() {
        guard let serviceUuidString = peripheralReadView.serviceUuidTextField.text,
              let characteristicUuidString = peripheralReadView.characteristicUuidTextField.text,
              let value = peripheralReadView.valueTextField.text else { return }

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
            properties: [.read],
            value: value.data(using: .utf8),
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

}
