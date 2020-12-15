import CoreBluetooth
import RxBluetoothKit
import RxSwift
import UIKit

class CentralSpecificViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var centralSpecificView = CentralSpecificView()

    override func loadView() {
        view = centralSpecificView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        centralSpecificView.readValueLabel.isEnabled = false
        centralSpecificView.connectButton.addTarget(self, action: #selector(handleConnectButton), for: .touchUpInside)
    }

    // MARK: - Private

    private var isConnected: Bool {
        connection != nil
    }
    private var connection: Disposable?
    private lazy var manager = CentralManager()

    @objc private func handleConnectButton() {
        isConnected ? diconnect() : connect()
    }

    private func connect() {
        guard let serviceUuidString = centralSpecificView.serviceUuidTextField.text,
              let characteristicUuidString = centralSpecificView.characteristicUuidTextField.text else { return }

        let serviceUuid = CBUUID(string: serviceUuidString)
        let characteristicUuid = CBUUID(string: characteristicUuidString)

        scanAndConnect(serviceUuid: serviceUuid, characteristicUuid: characteristicUuid)
    }

    private func diconnect() {
        connection?.dispose()
        connection = nil
        centralSpecificView.readValueLabel.isEnabled = false
        centralSpecificView.connectButton.setTitle("Connect", for: .normal)
    }

    private func scanAndConnect(serviceUuid: CBUUID, characteristicUuid: CBUUID) {
        let managerIsOn = manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }
            .map { _ in }

        connection = Observable.combineLatest(managerIsOn, Observable.just(manager)) { $1 }
            .flatMap { $0.scanForPeripherals(withServices: [serviceUuid]) }
            .timeout(.seconds(7), scheduler: MainScheduler.instance)
            .take(1)
            .flatMap { $0.peripheral.establishConnection() }
            .do(onNext: { [weak self] _ in self?.connected() })
            .flatMap { $0.discoverServices([serviceUuid]) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([characteristicUuid]) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .subscribe(
                onNext: { [weak self] in
                    guard let data = $0.value, let string = String(data: data, encoding: .utf8) else { return }
                    self?.updateValue(string)
                },
                onError: { [weak self] in
                    AlertPresenter.presentError(with: $0.printable, on: self?.navigationController)
                }
            )
    }

    private func updateValue(_ value: String) {
        centralSpecificView.readValueLabel.text = "Read value: " + value
    }

    private func connected() {
        centralSpecificView.readValueLabel.isEnabled = true
        centralSpecificView.connectButton.setTitle("Disconnect", for: .normal)
    }

}
