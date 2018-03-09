import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class PeripheralServicesViewController: UIViewController, CustomView {

    typealias ViewClass = PeripheralServicesView

    typealias PeripheralServicesDataSource = TableViewDataSource<[Service], PeripheralServicesViewModelItem>

    private let viewModel: PeripheralServicesViewModelType

    private let dataSource: PeripheralServicesDataSource

    private let disposeBag: DisposeBag = DisposeBag()

    init(with dataSource: PeripheralServicesDataSource, viewModel: PeripheralServicesViewModelType) {
        self.dataSource = dataSource
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        title = viewModel.displayedPeripheral.name ?? String(describing: viewModel.displayedPeripheral.identifier)
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
        customView.setTableView(dataSource: dataSource, delegate: self)
        registerCells()
        setDataSourceRefreshBlock()
        viewModel.connect()
        bindViewModelOutput()
        customView.toggleActivityIndicator(true)
    }

    private func bindViewModelOutput() {
        dataSource.bindItemsObserver(to: viewModel.servicesOutput)
        viewModel.servicesOutput.subscribe(onNext: { [unowned self] services in
            self.customView.toggleActivityIndicator(false)
        }, onError: { error in
            print(error)
        }).disposed(by: disposeBag)
    }

    private func registerCells() {
        customView.register(cellType: PeripheralServiceCell.self,
                forCellReuseIdentifier: String(describing: PeripheralServiceCell.self))
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }
}

extension PeripheralServicesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = self.dataSource.takeItemAt(index: indexPath.row) as? Service else { return }

        let viewModel = CharacteristicsViewModel(with: self.viewModel.bluetoothService, service: item)

        let dataItem = CharacteristicsViewModelItem("Characteristics", characteristicsRowItems: item.characteristics)

        let configureBlock: (UITableViewCell, Any) -> Void = { (cell, item) in
            guard let cell = cell as? UpdatableCell else {
                return
            }
            cell.update(with: item)
        }

        let dataSource = TableViewDataSource<[Characteristic], CharacteristicsViewModelItem>(dataItem: dataItem, configureBlock: configureBlock)

        let viewController = CharacteristicsViewController(with: dataSource, viewModel: viewModel)


        show(viewController, sender: self)
    }
}
