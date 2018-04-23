import RxSwift
import RxBluetoothKit
import UIKit

/*
    Generic UITableViewDataSource

    S - represents SectionModelItem, which stores
    information about given section's itemsCount, sectionName, cells' class and provides collection of model data
    check: DataSource/SectionModelItem.swift
*/

final class TableViewDataSource<S:SectionModelItem>: NSObject, UITableViewDataSource {

    // MARK: - Typealiases

    // Block set by a UIViewController, meant to be called for reloading data
    typealias RefreshDataBlock = () -> Void

    // Block set by a UIViewController, meant to be called inside at any OnError
    typealias OnErrorBlock = (_ error: Error) -> Void

    // MARK: - Fields
    private var refreshDataBlock: RefreshDataBlock = {
    }

    private var onErrorBlock: OnErrorBlock = { _ in
    }

    private let itemsSubject = PublishSubject<S.ModelDataType>()

    private let dataItem: S

    private let disposeBag = DisposeBag()

    // MARK: - Initialization
    init(dataItem: S) {
        self.dataItem = dataItem
        super.init()
        bindData()
    }

    // MARK: - Methods
    func bindData() {
        itemsSubject.subscribe(onNext: { [unowned self] item in
            self.dataItem.append(item)
            self.refreshDataBlock()
        }, onError: { [unowned self] (error) in
            self.onErrorBlock(error)
        }).disposed(by: disposeBag)
    }

    func bindItemsObserver(to observable: Observable<Result<S.ModelDataType, Error>>) {
        observable.subscribe(onNext: { [unowned self] result in
            switch result {
            case .success(let value):
                self.itemsSubject.onNext(value)
            case .error(let error):
                self.onErrorBlock(error)
            }
        }).disposed(by: disposeBag)
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
