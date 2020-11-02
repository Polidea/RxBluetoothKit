import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class PeripheralWriteViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var peripheralWriteView = PeripheralWriteView()

    override func loadView() {
        view = peripheralWriteView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralWriteView.advertiseButton.addTarget(self, action: #selector(handleAdvertiseButton), for: .touchUpInside)
        setupWriteAction()
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = PeripheralManager()
    private var characteristic: CBMutableCharacteristic?
    private var advertisement: Disposable?
    private var isAdvertising = false {
        didSet {
            let text = isAdvertising ? "Stop Advertising" : "Advertise"
            peripheralWriteView.advertiseButton.setTitle(text, for: .normal)
        }
    }

    private var managerIsOn: Observable<Void> {
        manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }
            .map { _ in }
    }

    @objc private func handleAdvertiseButton() {
        isAdvertising ? handleAdvertisingStop() : handleAdvertisingStart()
    }

    private func handleAdvertisingStart() {
        guard let serviceUuidString = peripheralWriteView.serviceUuidTextField.text,
              let characteristicUuidString = peripheralWriteView.characteristicUuidTextField.text else { return }

        let service = createService(uuidString: serviceUuidString)
        let characteristic = createCharacteristic(uuidString: characteristicUuidString)
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

    private func createCharacteristic(uuidString: String) -> CBMutableCharacteristic {
        let characteristicUuid = CBUUID(string: uuidString)
        return CBMutableCharacteristic(
            type: characteristicUuid,
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )
    }

    private func startAdvertising(service: CBMutableService) {
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

    private func setupWriteAction() {
        Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.observeDidReceiveWrite() }
            .compactMap { request in request.first?.value.flatMap { String(data: $0, encoding: .utf8) } }
            .subscribe(
                onNext: { [weak self] in self?.updateLabel(with: $0) },
                onError: { [weak self] in AlertPresenter.presentError(with: $0.printable, on: self?.navigationController) }
            )
            .disposed(by: disposeBag)
    }

    private func updateLabel(with text: String) {
        peripheralWriteView.writeLabel.text = "Written value: " + text
    }

}
