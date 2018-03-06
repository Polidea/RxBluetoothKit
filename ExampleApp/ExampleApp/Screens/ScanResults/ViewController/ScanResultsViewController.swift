import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = ScanResultsView

    typealias ScansResultDataSource = TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    private let dataSource: TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    private let viewModel: ScanResultsViewModelType

    private var presenter: Presenter!

    private let disposeBag: DisposeBag = DisposeBag()

    init(with dataSource: ScansResultDataSource, viewModel: ScanResultsViewModelType) {
        self.dataSource = dataSource
        self.viewModel = viewModel
        self.presenter = ViewControllerPresenter()
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
        presenter.viewController = self.navigationController
        customView.setTableView(dataSource: dataSource, delegate: self)
        setDataSourceRefreshBlock()
        registerCells()
        setNavigationBar()
        dataSource.bindData()
        bindRx()
    }

    private func bindRx() {
        dataSource.bindItemsObserver(to: viewModel.scanningOutput)
    }

    private func setNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start scanning",
                style: .plain,
                target: self,
                action: #selector(scanningAction))
    }

    @objc private func scanningAction() {
        viewModel.scanAction()
        adjustTitle()
        if viewModel.isScanning {
            dataSource.bindData()
        }
    }

    private func adjustTitle() {
        navigationItem.rightBarButtonItem?.title = viewModel.isScanning ? "Stop scan" : "Start scan"
        title = viewModel.isScanning ? "Scanning" : nil
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func registerCells() {
        customView.tableView.register(ScanResultTableViewCell.self,
                forCellReuseIdentifier: String(describing: ScanResultTableViewCell.self))
    }
}

extension ScanResultsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = self.dataSource.takeItemAt(index: indexPath.row) as? ScannedPeripheral else { return }

        RxBluetoothKitService.shared.peripheral = item.peripheral

        let viewModel = PeripheralServicesViewModel()

        let dataItem = PeripheralServicesViewModelItem("Services", peripheralRowItems: item.peripheral.services)

        let configureBlock: (UITableViewCell, Any) -> Void = { (cell, item) in
            guard let cell = cell as? UpdatableCell else {
                return
            }
            cell.update(with: item)
        }

        let dataSource = TableViewDataSource<[Service], PeripheralServicesViewModelItem>(dataItem: dataItem, configureBlock: configureBlock)

        let viewController = PeripheralServicesViewController(with: dataSource, viewModel: viewModel)

        presenter.push(viewController: viewController)
    }
}
