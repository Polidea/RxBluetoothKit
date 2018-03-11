import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = BaseView

    typealias ScansResultDataSource = TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    private let dataSource: TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    private let viewModel: ScanResultsViewModelType

    private let disposeBag: DisposeBag = DisposeBag()

    init(with dataSource: ScansResultDataSource, viewModel: ScanResultsViewModelType) {
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
        customView.setTableView(dataSource: dataSource, delegate: self)
        setDataSourceRefreshBlock()
        registerCells()
        setNavigationBar()
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

    @objc private func connectAction(_ button: UIButton) {
        guard let cell = button.superview as? UITableViewCell,
              let indexPath = customView.indexPath(for: cell)
                else {
            return
        }

        guard let scannedPeripheral = dataSource.takeItemAt(index: indexPath.row) as? ScannedPeripheral else {
            return
        }

        showPeripheralServices(for: scannedPeripheral)
    }

    private func showPeripheralServices(for scannedPeripheral: ScannedPeripheral) {

        let dataItem = PeripheralServicesViewModelItem("Services",
                peripheralRowItems: scannedPeripheral.peripheral.services)

        let configureBlock: (UITableViewCell, Any) -> Void = { (cell, item) in
            guard let cell = cell as? UpdatableCell else {
                return
            }
            cell.update(with: item)
        }

        let viewModel = PeripheralServicesViewModel(with: self.viewModel.bluetoothService,
                peripheral: scannedPeripheral.peripheral)

        let dataSource = TableViewDataSource<[Service], PeripheralServicesViewModelItem>(dataItem: dataItem,
                configureBlock: configureBlock)

        let viewController = PeripheralServicesViewController(with: dataSource, viewModel: viewModel)

        show(viewController, sender: self)
    }

    private func adjustTitle() {
        navigationItem.rightBarButtonItem?.title = viewModel.isScanning ? "Stop scan" : "Start scan"
        title = viewModel.isScanning ? "Scanning..." : ""
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func registerCells() {
        customView.register(cellType: ScanResultTableViewCell.self,
                forCellReuseIdentifier: String(describing: ScanResultTableViewCell.self))
    }
}

extension ScanResultsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ScanResultTableViewCell else {
            return
        }
        cell.setConnectTarget(self, action: #selector(connectAction), for: .touchUpInside)
    }
}
