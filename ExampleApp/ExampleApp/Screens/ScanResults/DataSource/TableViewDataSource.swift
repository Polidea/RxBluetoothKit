import RxSwift
import UIKit

class TableViewDataSource: NSObject, UITableViewDataSource {

    typealias CellConfigurationBlock = (_ cell: UITableViewCell, _ item: Any) -> Void

    var itemsObserver: AnyObserver<[SectionModelItem]> {
        return itemsSubject.asObserver()
    }

    var itemsObservable: Observable<[SectionModelItem]> {
        return itemsSubject.asObservable()
    }

    private let itemsSubject = PublishSubject<[SectionModelItem]>()

    private var configureBlock: CellConfigurationBlock

    private var items: [SectionModelItem] = []

    init(configureBlock: @escaping CellConfigurationBlock ){
        self.configureBlock = configureBlock
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
