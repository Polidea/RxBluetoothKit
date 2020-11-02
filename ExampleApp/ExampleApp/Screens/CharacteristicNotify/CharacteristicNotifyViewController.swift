import RxBluetoothKit
import RxSwift
import UIKit

class CharacteristicNotifyViewController: UIViewController {

    init(characteristic: Characteristic, bluetoothProvider: BluetoothProvider) {
        self.characteristic = characteristic
        self.bluetoothProvider = bluetoothProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var characteristicNotifyView = CharacteristicNotifyView()

    override func loadView() {
        view = characteristicNotifyView
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
            .flatMap { [characteristic, bluetoothProvider] in bluetoothProvider.getValueUpdates(for: characteristic) }
            .subscribe(
                onNext: { [weak self] in self?.characteristicNotifyView.label.text = "Updated value: " + $0 },
                onError: { [weak self] in AlertPresenter.presentError(with: $0.printable, on: self?.navigationController) }
            )
            .disposed(by: disposeBag)
    }

}
