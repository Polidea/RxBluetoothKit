import RxBluetoothKit
import RxSwift
import UIKit

class CharacteristicReadViewController: UIViewController {

    init(characteristic: Characteristic, bluetoothProvider: BluetoothProvider) {
        self.characteristic = characteristic
        self.bluetoothProvider = bluetoothProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var characteristicReadView = CharacteristicReadView()

    override func loadView() {
        view = characteristicReadView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewDidAppearSubject.onNext(())
    }

    // MARK: - Private

    private let characteristic: Characteristic
    private let bluetoothProvider: BluetoothProvider
    private let viewDidAppearSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    private func setupBindings() {
        viewDidAppearSubject
            .take(1)
            .flatMap { [characteristic, bluetoothProvider] in bluetoothProvider.readValue(for: characteristic) }
            .subscribe(
                onNext: { [weak self] in self?.characteristicReadView.label.text = "Read value: " + $0 },
                onError: { [weak self] in AlertPresenter.presentError(with: $0.printable, on: self?.navigationController) }
            )
            .disposed(by: disposeBag)
    }

}
