import RxSwift
import RxBluetoothKit
import UIKit

/* Generic UITableViewDataSource. I - represents model type, S - represents SectionModelItem, which stores
   information about given section's itemsCount, sectionName, cells' class and provides collection of model data
   check: DataSource.SectionModelItem.swift
*/

final class TableViewDataSource<I, S:SectionModelItem>: NSObject, UITableViewDataSource where I == S.ModelDataType {

    // MARK: - Typealiases
    // Block used to configure UITableViewCell, passed into init
    typealias CellConfigurationBlock = (_ cell: UITableViewCell, _ item: Any) -> Void

    // Block set by given UIViewController, meant to be called for reloading data
    typealias RefreshDataBlock = () -> Void

    // Block set by given UIViewController, meant to be called inside at any OnError
    typealias OnErrorBlock = (_ error: Error) -> Void

    // MARK: - Fields
    var refreshDataBlock: RefreshDataBlock?

    var onErrorBlock: OnErrorBlock?
    
    private let itemsSubject = PublishSubject<I>()

    private let dataItem: S

    private let disposeBag: DisposeBag = DisposeBag()

    private var configureBlock: CellConfigurationBlock

    // MARK: - Initialization
    init(dataItem: S, configureBlock: @escaping CellConfigurationBlock) {
        self.dataItem = dataItem
        self.configureBlock = configureBlock
        super.init()
        bindData()
    }

    // MARK: - Methods
    func bindData() {
        itemsSubject.subscribe(onNext: { [weak self] item in
            self?.dataItem.append(item)
            self?.refreshData()
        }, onError: { [unowned self] (error) in
            self.onErrorBlock?(error)
        }).disposed(by: disposeBag)
    }

    func bindItemsObserver(to observable: Observable<I>) {
        observable.bind(to: itemsSubject).disposed(by: disposeBag)
    }

    func takeItemAt(index: Int) -> Any {
        return dataItem.rowData[index]
    }

    private func refreshData() {
        guard let refreshDataBlock = refreshDataBlock else {
            return
        }
        refreshDataBlock()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItem.itemsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: dataItem.cellClass)
        let item = dataItem.rowData[indexPath.item]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) else {
            return UITableViewCell()
        }

        configureBlock(cell, item)
        return cell
    }
}
