import RxBluetoothKit
import UIKit

class CharacteristicWriteViewController: UIViewController {

    init(characteristic: Characteristic, bluetoothProvider: BluetoothProvider) {
        self.characteristic = characteristic
        self.bluetoothProvider = bluetoothProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var characteristicWriteView = CharacteristicWriteView()

    override func loadView() {
        view = characteristicWriteView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        characteristicWriteView.writeButton.addTarget(self, action: #selector(handleWriteButton), for: .touchUpInside)
    }

    // MARK: - Private

    private let characteristic: Characteristic
    private let bluetoothProvider: BluetoothProvider

    @objc private func handleWriteButton() {
        guard let value = characteristicWriteView.valueTextField.text else { return }

        bluetoothProvider.write(value: value, for: characteristic)
    }

}
