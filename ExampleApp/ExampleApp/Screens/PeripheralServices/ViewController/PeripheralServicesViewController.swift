import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class PeripheralServicesViewController: UIViewController, CustomView {

    typealias ViewClass = PeripheralServicesView

    typealias PeripheralServicesDataSource = TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

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

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
