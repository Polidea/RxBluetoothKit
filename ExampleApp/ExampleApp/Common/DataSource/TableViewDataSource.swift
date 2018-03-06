import RxSwift
import RxBluetoothKit
import UIKit

class TableViewDataSource<I, S: SectionModelItem>: NSObject, UITableViewDataSource {

    typealias CellConfigurationBlock = (_ cell: UITableViewCell, _ item: I) -> Void

    typealias RefreshDataBlock = () -> Void

    var itemsObservable: Observable<I> {
        return itemsSubject.asObservable()
    }

    var refreshDataBlock: RefreshDataBlock?

    private let itemsSubject = PublishSubject<I>()

    private var configureBlock: CellConfigurationBlock

    private let dataItem: S

    private let disposeBag: DisposeBag = DisposeBag()

    init(dataItem: S, configureBlock: @escaping CellConfigurationBlock) {
        self.dataItem = dataItem
        self.configureBlock = configureBlock
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItem.itemsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: dataItem.cellClass())
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier),
              let item = dataItem.rowData[indexPath.item] as? I
                else {
            return UITableViewCell()
        }

        configureBlock(cell, item)
        return cell
    }

    func bindNewItems() {
        itemsObservable.subscribe(onNext: { [weak self] item in
            self?.dataItem.append(item)
            self?.refreshData()
        }, onError: { (error) in
            print(error)
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
}
