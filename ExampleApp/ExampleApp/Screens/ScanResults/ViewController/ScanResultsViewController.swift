import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = BaseView

    typealias ScansResultDataSource = TableViewDataSource<ScanResultsViewModelItem>

    private let dataSource: TableViewDataSource<ScanResultsViewModelItem>

    private let viewModel: ScanResultsViewModelType

    private let disposeBag = DisposeBag()

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
        setupTableView()
        setNavigationBar()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customView.refreshTableView()
    }

    private func setupTableView() {
        customView.setTableView(dataSource: dataSource, delegate: self)
        registerCells()
        setDataSourceRefreshBlock()
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.setRefreshBlock { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func registerCells() {
        customView.register(cellType: ScanResultTableViewCell.self,
                forCellReuseIdentifier: String(describing: ScanResultTableViewCell.self))
    }


    private func setNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Constant.Strings.startScanning,
                style: .plain,
                target: self,
                action: #selector(scanningAction))
    }

    private func bindViewModel() {
        dataSource.bindItemsObserver(to: viewModel.scanningOutput)
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

    private func adjustTitle() {
        navigationItem.rightBarButtonItem?.title = viewModel.isScanning ? Constant.Strings.stopScanning : Constant.Strings.startScanning
        title = viewModel.isScanning ? Constant.Strings.scanning : nil
    }


    private func showPeripheralServices(for scannedPeripheral: ScannedPeripheral) {

        let dataItem = PeripheralServicesViewModelItem(Constant.Strings.servicesSectionTitle)

        let viewModel = PeripheralServicesViewModel(with: self.viewModel.bluetoothService, peripheral: scannedPeripheral.peripheral)

        let dataSource = TableViewDataSource<PeripheralServicesViewModelItem>(dataItem: dataItem)

        let viewController = PeripheralServicesViewController(with: dataSource, viewModel: viewModel)

        show(viewController, sender: self)
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
