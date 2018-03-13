import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

final class PeripheralServicesViewController: UIViewController, CustomView {

    typealias ViewClass = BaseView

    typealias PeripheralServicesDataSource = TableViewDataSource<Service, PeripheralServicesViewModelItem>

    private let viewModel: PeripheralServicesViewModelType

    private let dataSource: PeripheralServicesDataSource

    private let disposeBag: DisposeBag = DisposeBag()

    init(with dataSource: PeripheralServicesDataSource, viewModel: PeripheralServicesViewModelType) {
        self.dataSource = dataSource
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = ViewClass()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setCustomView()
        setupTableView()
        setDataSourceBlocks()
        adjustTitle()
        bindViewModel()
    }

    private func setCustomView() {
        customView.toggleActivityIndicator(true)
    }

    private func setupTableView() {
        customView.setTableView(dataSource: dataSource, delegate: self)
        registerCells()
    }

    private func setDataSourceBlocks() {
        setDataSourceRefreshBlock()
        setDataSourceOnErrorBlock()
    }

    private func bindViewModel() {
        viewModel.connect()
        bindViewModelOutput()
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func setDataSourceOnErrorBlock() {
        dataSource.onErrorBlock = { [weak self] error in
            self?.showAlert("\(error.self)", message: error.localizedDescription)
        }
    }

    private func registerCells() {
        customView.register(cellType: PeripheralServiceCell.self,
                forCellReuseIdentifier: String(describing: PeripheralServiceCell.self))
    }

    private func adjustTitle() {
        title = viewModel.displayedPeripheral.name ?? String(describing: viewModel.displayedPeripheral.identifier)
    }

    private func bindViewModelOutput() {
        bindServiceOutputToDataSource()
        subscribeToServiceOutput()
        subscribeToDisconnectionOutput()
        subscribeToErrorOutput()
    }

    private func bindServiceOutputToDataSource() {
        dataSource.bindItemsObserver(to: viewModel.servicesOutput)
    }

    private func subscribeToServiceOutput() {
        viewModel.servicesOutput.subscribe(onNext: { [unowned self] services in
            self.customView.toggleActivityIndicator(false)
        }, onError: { [unowned self] error in
            self.showAlert("\(error.self)", message: error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    private func subscribeToDisconnectionOutput() {
        viewModel.disconnectionOutput.subscribe(onNext: { [unowned self] disconnection in
            let message = disconnection.1?.localizedDescription ?? ""
            self.showAlert("Disconnected: \(disconnection.0)", message: message)
         }).disposed(by: disposeBag)
    }

    private func subscribeToErrorOutput() {
        viewModel.errorOutput.subscribe(onNext: { [unowned self] error in
            self.showAlert("\(error.self)", message: error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    private func showAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension PeripheralServicesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = self.dataSource.takeItemAt(index: indexPath.row) as? Service else {
            return
        }

        let viewModel = CharacteristicsViewModel(with: self.viewModel.bluetoothService, service: item)

        let dataItem = CharacteristicsViewModelItem(Constant.Strings.characteristicsSectionTitle,
                characteristicsRowItems: item.characteristics)

        let configureBlock: (UITableViewCell, Any) -> Void = { (cell, item) in
            guard let cell = cell as? UpdatableCell else {
                return
            }
            cell.update(with: item)
        }

        let dataSource = TableViewDataSource<Characteristic, CharacteristicsViewModelItem>(dataItem: dataItem, configureBlock: configureBlock)

        let viewController = CharacteristicsViewController(with: dataSource, viewModel: viewModel)

        show(viewController, sender: self)
    }
}
