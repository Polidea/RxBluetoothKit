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

    private func addWriteActions(to actionSheet: UIAlertController) {
        let writeValueNotificationAction = UIAlertAction(title: "Write", style: .default) { _ in
            self.showWriteFieldForCharacteristic()
        }
        actionSheet.addAction(writeValueNotificationAction)
    }

    private func addReadActions(to actionSheet: UIAlertController) {
        let readValueNotificationAction = UIAlertAction(title: "Read", style: .default) { [weak self] _ in
            self?.viewModel.triggerValueRead()
        }
        actionSheet.addAction(readValueNotificationAction)
    }

    private func addNotificationActions(to actionSheet: UIAlertController) {
        let turnNotificationOffAction = UIAlertAction(title: "Turn OFF notifications", style: .default) { _ in
            self.viewModel.setNotificationsState(enabled: false)
        }
        let turnNotificationOnAction = UIAlertAction(title: "Turn ON notifications", style: .default) { _ in
            self.viewModel.setNotificationsState(enabled: true)
        }
        actionSheet.addAction(turnNotificationOffAction)
        actionSheet.addAction(turnNotificationOnAction)
    }

    private func addDismissAction(to actionSheet: UIAlertController) {
        let dismissAction = UIAlertAction(title: "Cancel", style: .destructive) { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
        actionSheet.addAction(dismissAction)
    }

    fileprivate func showWriteFieldForCharacteristic() {
        let valueWriteController = UIAlertController(title: "Write value", message: "Specify value in HEX to write ",
                preferredStyle: .alert)
        valueWriteController.addTextField { _ in
        }
        valueWriteController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        valueWriteController.addAction(UIAlertAction(title: "Write", style: .default) { _ in

            if let _text = valueWriteController.textFields?.first?.text {
                self.viewModel.writeValueForCharacteristic(hexadecimalString: _text)
            }

        })
        present(valueWriteController, animated: true, completion: nil)
    }
}

extension CharacteristicsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = dataSource.takeItemAt(index: indexPath.row) as? Characteristic else {
            return
        }
        viewModel.setCurrent(characteristic: characteristic)
        let actionSheet = UIAlertController(title: "Choose action", message: nil, preferredStyle: .actionSheet)

        if characteristic.properties.contains(.notify) {
            addNotificationActions(to: actionSheet)
        }
        if characteristic.properties.contains(.read) {
            addReadActions(to: actionSheet)
        }

        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
            addWriteActions(to: actionSheet)
        }

        addDismissAction(to: actionSheet)

        present(actionSheet, animated: true, completion: nil)
    }
}
