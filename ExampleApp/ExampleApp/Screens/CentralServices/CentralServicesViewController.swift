import RxBluetoothKit
import RxSwift
import UIKit

class CentralSericesViewController: UITableViewController {

    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Peripheral's services"
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        tableView.register(CentralServiceCell.self, forCellReuseIdentifier: CentralServiceCell.reuseId)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        didAppearSubject.onNext(())
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CentralServiceCell.reuseId, for: indexPath) as? CentralServiceCell else {
            fatalError("Something went wrong :(")
        }

        let service = services[indexPath.row]
        cell.uuidLabel.text = service.uuid.uuidString
        cell.isPrimaryLabel.text = "isPrimary: \(service.isPrimary)"
        cell.characterisicsCountLabel.text = "chcarac. count: \(service.characteristics?.count ?? -1)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = services[indexPath.row]
        service.discoverCharacteristics(nil)
            .subscribe(
                onSuccess: { [weak self] in self?.pushCharacteristicsController(with: $0) },
                onError: { [weak self] in AlertPresenter.presentError(with: $0.printable, on: self?.navigationController) }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Private

    private let peripheral: Peripheral
    private let didAppearSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    private var services = [Service]() {
        didSet {
            tableView.reloadData()
        }
    }

    private func setupBindings() {
        didAppearSubject
            .take(1)
            .flatMap { [peripheral] in peripheral.discoverServices(nil) }
            .subscribe(
                onNext: { [weak self] in self?.services = $0 },
                onError: { [weak self] in
                    AlertPresenter.presentError(with: $0.printable, on: self?.navigationController)
                }
            )
            .disposed(by: disposeBag)
    }

    private func pushCharacteristicsController(with characteristics: [Characteristic]) {
        let controller = CharacteristicsViewController(characteristics: characteristics)
        navigationController?.pushViewController(controller, animated: true)
    }

}

extension Error {

    var printable: String {
        if let bleError = self as? BluetoothError {
            return bleError.description
        }

        return localizedDescription
    }

}
