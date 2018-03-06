import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class PeripheralServicesViewController: UIViewController, CustomView {

    typealias ViewClass = PeripheralServicesView

    typealias PeripheralServicesDataSource = TableViewDataSource<[Service], PeripheralServicesViewModelItem>

    private let viewModel: PeripheralServicesViewModelType

    private let dataSource: PeripheralServicesDataSource

    private var presenter: Presenter!

    init(with dataSource: PeripheralServicesDataSource, viewModel: PeripheralServicesViewModelType) {
        self.dataSource = dataSource
        self.viewModel = viewModel
        self.presenter = ViewControllerPresenter()
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
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
        presenter.viewController = self
        customView.setTableView(dataSource: dataSource, delegate: self)
        registerCells()
        setDataSourceRefreshBlock()
        viewModel.connect()
        bindViewModelOutput()
        dataSource.bindData()
    }

    private func bindViewModelOutput() {
        dataSource.bindItemsObserver(to: viewModel.servicesOutput)
    }

    private func registerCells() {
        customView.tableView.register(PeripheralServiceCell.self,
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
        return 120.0
    }
}
