import RxBluetoothKit
import RxSwift
import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = ScanResultsView

    let centralManager: CentralManager = CentralManager(queue: .main)

    private let disposeBag: DisposeBag = DisposeBag()

    private let dataSource: TableViewDataSource

    init(with dataSource: TableViewDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = ViewClass()
        testCentralManager()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customView.setTableView(dataSource: dataSource, delegate: self)
    }

    private func testCentralManager() {
        centralManager.observeState()
                .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    return self.centralManager.scanForPeripherals(withServices: nil)
                }
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { (peripheral) in
                    print(peripheral.rssi, peripheral.advertisementData, peripheral.peripheral)
                })
                .disposed(by: disposeBag)
    }
}


extension ScanResultsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
}
