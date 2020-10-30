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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        setupReadingValues()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.onNext(())
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        values.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let value = values[indexPath.row]
        cell.textLabel?.text = value
        return cell
    }

    // MARK: - Private

    private let characteristics: [Characteristic]
    private let bluetoothProvider: BluetoothProvider
    private var values: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private let viewDidAppearSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    private func setupReadingValues() {
        viewDidAppearSubject.asObservable()
            .take(1)
            .flatMap { [characteristics] in Observable.from(characteristics) }
            .flatMap { [bluetoothProvider] in bluetoothProvider.readValue(for: $0) }
            .subscribe(
                onNext: { [weak self] in self?.values.append($0) },
                onError: { [weak self] in
                    AlertPresenter.presentError(with: $0.printable, on: self?.navigationController)
                }
            )
            .disposed(by: disposeBag)
    }

}
