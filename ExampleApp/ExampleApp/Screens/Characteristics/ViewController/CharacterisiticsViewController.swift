import RxBluetoothKit
import RxSwift
import RxCocoa
import UIKit

class CharacteristicsViewController: UIViewController, CustomView {

    typealias ViewClass = CharacteristicsView

    typealias CharacteristicsDataSource = TableViewDataSource<[Characteristic], CharacteristicsViewModelItem>

    private let viewModel: CharacteristicsViewModelType

    private let dataSource: CharacteristicsDataSource

    private let disposeBag: DisposeBag = DisposeBag()

    init(with dataSource: CharacteristicsDataSource, viewModel: CharacteristicsViewModelType) {
        self.dataSource = dataSource
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = ViewClass()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        setDataSourceRefreshBlock()
        customView.setTableView(dataSource: dataSource, delegate: self)
        dataSource.bindItemsObserver(to: viewModel.characteristicsOutput)
//        dataSource.bindData()
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.refreshDataBlock = { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func registerCells() {
        customView.tableView.register(CharacterisiticsTableViewCell.self,
                forCellReuseIdentifier: String(describing: CharacterisiticsTableViewCell.self))
    }
}

extension CharacteristicsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
