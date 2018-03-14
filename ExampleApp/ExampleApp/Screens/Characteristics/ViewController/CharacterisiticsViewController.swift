import RxBluetoothKit
import RxSwift
import RxCocoa
import UIKit

final class CharacteristicsViewController: UIViewController, CustomView {

    typealias ViewClass = BaseView

    typealias CharacteristicsDataSource = TableViewDataSource<CharacteristicsViewModelItem>

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
        setupTableView()
        setDataSourceRefreshBlock()
        bindViewModel()
    }

    private func setupTableView() {
        customView.setTableView(dataSource: dataSource, delegate: self)
        registerCells()
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource.setRefreshBlock { [weak self] in
            self?.customView.refreshTableView()
        }
    }

    private func bindViewModel() {
        subscribeViewModelOutputs()
        dataSource.bindItemsObserver(to: viewModel.characteristicsOutput)
    }

    private func subscribeViewModelOutputs() {
        subscribeDataUpdateOutput()
        subscribeAlertTriggerOutput()
    }

    private func subscribeDataUpdateOutput() {
        viewModel.dataUpdateOutput.subscribe(onNext: { [unowned self]  _ in
            self.customView.refreshTableView()
        }).disposed(by: disposeBag)
    }

    private func subscribeAlertTriggerOutput() {
        viewModel.alertTriggerOutput.subscribe(onNext: { [unowned self] message in
            self.showAlert(title: Constant.Strings.titleSuccess, message: message)
        }).disposed(by: disposeBag)
    }

    private func registerCells() {
        customView.register(cellType: CharacterisiticsTableViewCell.self,
                forCellReuseIdentifier: String(describing: CharacterisiticsTableViewCell.self))
    }

    private func addWriteActions(to actionSheet: UIAlertController) {
        let writeValueNotificationAction = UIAlertAction(title: Constant.Strings.titleWrite,
                style: .default) { _ in
            self.showWriteFieldForCharacteristic()
        }
        actionSheet.addAction(writeValueNotificationAction)
    }

    private func addReadActions(to actionSheet: UIAlertController) {
        let readValueNotificationAction = UIAlertAction(title: Constant.Strings.titleRead,
                style: .default) { [weak self] _ in
            self?.viewModel.triggerValueRead()
        }
        actionSheet.addAction(readValueNotificationAction)
    }

    private func addNotificationActions(to actionSheet: UIAlertController) {
        let turnNotificationOffAction = UIAlertAction(title: Constant.Strings.turnOffNotifications,
                style: .default) { _ in
            self.viewModel.setNotificationsState(enabled: false)
        }
        let turnNotificationOnAction = UIAlertAction(title: Constant.Strings.turnOnNotifications,
                style: .default) { _ in
            self.viewModel.setNotificationsState(enabled: true)
        }
        actionSheet.addAction(turnNotificationOffAction)
        actionSheet.addAction(turnNotificationOnAction)
    }

    private func addDismissAction(to actionSheet: UIAlertController) {
        let dismissAction = UIAlertAction(title: Constant.Strings.titleCancel,
                style: .cancel) { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
        actionSheet.addAction(dismissAction)
    }

    fileprivate func showWriteFieldForCharacteristic() {
        let valueWriteController = UIAlertController(title: Constant.Strings.titleWriteValue,
                message: Constant.Strings.hexValue,
                preferredStyle: .alert)
        valueWriteController.addTextField { _ in
        }

        valueWriteController.addAction(UIAlertAction(title: Constant.Strings.titleCancel, style: .cancel, handler: nil))
        valueWriteController.addAction(UIAlertAction(title: Constant.Strings.titleWrite, style: .default) { _ in

            if let _text = valueWriteController.textFields?.first?.text {
                self.viewModel.writeValueForCharacteristic(hexadecimalString: _text)
            }

        })
        present(valueWriteController, animated: true, completion: nil)

    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: Constant.Strings.titleOk, style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension CharacteristicsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = dataSource.takeItemAt(index: indexPath.row) as? Characteristic else {
            return
        }
        viewModel.setCurrent(characteristic: characteristic)

        let actionSheet = UIAlertController(title: Constant.Strings.titleChooseAction,
                message: nil,
                preferredStyle: .actionSheet)

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
