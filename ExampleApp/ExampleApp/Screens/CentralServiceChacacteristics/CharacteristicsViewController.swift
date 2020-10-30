import RxBluetoothKit
import RxSwift
import UIKit

class CharacteristicsViewController: UITableViewController {

    init(characteristics: [Characteristic], bluetoothProvider: BluetoothProvider) {
        self.characteristics = characteristics
        self.bluetoothProvider = bluetoothProvider
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Characteristics"
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(CharacteristicCell.self, forCellReuseIdentifier: CharacteristicCell.reuseId)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        characteristics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CharacteristicCell.reuseId, for: indexPath) as? CharacteristicCell else {
            fatalError("Something went horribly wrong :(")
        }

        let characterstic = characteristics[indexPath.row]
        cell.identifierLabel.text = characterstic.uuid.uuidString
        [cell.readButton, cell.updateButton, cell.writeButton].forEach { $0.tag = indexPath.row }
        cell.readButton.addTarget(self, action: #selector(handleReadButton), for: .touchUpInside)
        cell.updateButton.addTarget(self, action: #selector(handleUpdateButton), for: .touchUpInside)
        cell.writeButton.addTarget(self, action: #selector(handleWriteButton), for: .touchUpInside)
        return cell
    }

    // MARK: - Private

    private let characteristics: [Characteristic]
    private let bluetoothProvider: BluetoothProvider

    @objc private func handleReadButton(_ sender: UIButton) {
        let characteristic = characteristics[sender.tag]
        let controller = CharacteristicReadViewController(
            characteristic: characteristic,
            bluetoothProvider: bluetoothProvider
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func handleUpdateButton(_ sender: UIButton) {
        print("update \(sender.tag)")
    }

    @objc private func handleWriteButton(_ sender: UIButton) {
        print("write \(sender.tag)")
    }

}
