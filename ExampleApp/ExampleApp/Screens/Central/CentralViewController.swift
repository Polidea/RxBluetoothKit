import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class CentralViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var centralView = CentralView()

    override func loadView() {
        view = centralView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        centralView.connectButton.addTarget(self, action: #selector(handleConnectButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private lazy var manager = CentralManager()

    @objc private func handleConnectButton() {
        guard let serviceUuidString = centralView.serviceUuidTextField.text,
              let characteristicUuidString = centralView.characteristicUuidTextField.text else { return }

        let serviceUuid = CBUUID(string: serviceUuidString)
        let characteristicUuid = CBUUID(string: characteristicUuidString)

        scanAndConnect(serviceUuid: serviceUuid, characteristicUuid: characteristicUuid)
    }

    private func scanAndConnect(serviceUuid: CBUUID, characteristicUuid: CBUUID) {
        let managerIsOn = manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }
            .map { _ in }

        Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.scanForPeripherals(withServices: [serviceUuid]) }
            .take(1)
            .flatMap { $0.peripheral.establishConnection() }
            .flatMap { $0.discoverServices([serviceUuid]) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([characteristicUuid]) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.readValue() }
            .subscribe(onNext: {
                guard let data = $0.value else { return }
                print(String(data: data, encoding: .utf8))
            })
            .disposed(by: disposeBag)
    }

}
