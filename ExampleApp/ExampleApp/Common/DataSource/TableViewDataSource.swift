import RxSwift
import RxBluetoothKit
import UIKit

/* Generic UITableViewDataSource. I - represents model type, S - represents SectionModelItem, which stores
   information about given section's itemsCount, sectionName, cells' class and provides collection of model data
   check: DataSource.SectionModelItem.swift
*/

final class TableViewDataSource<S: SectionModelItem>: NSObject, UITableViewDataSource {

    // MARK: - Typealiases

    // Block set by given UIViewController, meant to be called for reloading data
    typealias RefreshDataBlock = () -> Void

    // Block set by given UIViewController, meant to be called inside at any OnError
    typealias OnErrorBlock = (_ error: Error) -> Void

    // MARK: - Fields
    private var refreshDataBlock: RefreshDataBlock = {
    }

    private var onErrorBlock: OnErrorBlock = { _ in
    }

    private let itemsSubject = PublishSubject<S.ModelDataType>()

    private let dataItem: S

    private let disposeBag: DisposeBag = DisposeBag()

    // MARK: - Initialization
    init(dataItem: S) {
        self.dataItem = dataItem
        super.init()
        bindData()
    }


    // MARK: - Methods
    func bindData() {
        itemsSubject.subscribe(onNext: { [weak self] item in
            self?.dataItem.append(item)
            self?.refreshData()
        }, onError: { [unowned self] (error) in
            self.onErrorBlock(error)
        }).disposed(by: disposeBag)
    }

    func bindItemsObserver(to observable: Observable<S.ModelDataType>) {
        observable.bind(to: itemsSubject).disposed(by: disposeBag)
    }

    func setRefreshBlock(_ block: @escaping RefreshDataBlock) {
        refreshDataBlock = block
    }

    func setOnErrorBlock(_ block: @escaping OnErrorBlock) {
        onErrorBlock = block
    }

    func takeItemAt(index: Int) -> Any {
        return dataItem.rowData[index]
    }

    private func refreshData() {
        refreshDataBlock()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItem.itemsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: dataItem.cellClass)
        let item = dataItem.rowData[indexPath.item]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? S.CellType else {
            return UITableViewCell()
        }
        cell.update(with: item)
        return cell
    }
}
