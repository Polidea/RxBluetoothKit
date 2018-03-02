import RxBluetoothKit
import RxCocoa
import RxSwift
import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = ScanResultsView

    typealias ScansResultDataSource = TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    let centralManager: CentralManager = CentralManager(queue: .main)

    private let disposeBag: DisposeBag = DisposeBag()

    private let dataSource: TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>

    private let scheduler: ConcurrentDispatchQueueScheduler

    private var testDisposable: Disposable!

    init(with dataSource: ScansResultDataSource) {
        self.dataSource = dataSource
        let timerQueue = DispatchQueue(label: "com.polidea.rxbluetoothkit.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = ViewClass()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customView.setTableView(dataSource: dataSource, delegate: self)
        setDataSourceRefreshBlock()
        registerCells()
        dataSource.bindNewItems()
        testCentralManager()
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func registerCells() {
        customView.tableView.register(ScanResultTableViewCell.self, forCellReuseIdentifier: String(describing: ScanResultTableViewCell.self))
    }

    private func testCentralManager() {
        testDisposable = centralManager.observeState()
                .timeout(4.0, scheduler: scheduler)
                .take(1)
                .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    return self.centralManager.scanForPeripherals(withServices: nil)
            }.bind(to: dataSource.itemsObserver)

        dataSource.bindNewItems()
    }
}

extension ScanResultsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
    }
}
