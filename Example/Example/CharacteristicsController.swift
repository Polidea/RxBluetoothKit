//
//  CharacteristicsTableViewController.swift
//  Example
//
//  Created by Kacper Harasim on 14.04.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import CoreBluetooth

class CharacteristicsController: UIViewController {

    var service: Service!

    private let disposeBag = DisposeBag()

    @IBOutlet weak var characteristicsTableView: UITableView!
    
    fileprivate var characteristicsList: [Characteristic] = []
    fileprivate let characteristicCellId = "CharacteristicCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        characteristicsTableView.delegate = self
        characteristicsTableView.dataSource = self
        characteristicsTableView.estimatedRowHeight = 40.0
        characteristicsTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCharacteristics(for: service)
    }

    private func getCharacteristics(for service: Service) {
        service.discoverCharacteristics(nil)
            .subscribe(onNext: { characteristics in
                self.characteristicsList = characteristics
                self.characteristicsTableView.reloadData()
            }).addDisposableTo(disposeBag)
    }

    fileprivate func setNotificationsState(enabled: Bool, characteristic: Characteristic) {
        characteristic.setNotifyValue(enabled)
            .subscribe(onNext: { [weak self] _ in
                self?.characteristicsTableView.reloadData()
            }).addDisposableTo(disposeBag)
    }

    fileprivate func showWriteFieldForCharacteristic(characteristic: Characteristic) {
        let valueWriteController = UIAlertController(title: "Write value", message: "Specify value in HEX to write ",
                                                     preferredStyle: .alert)
        valueWriteController.addTextField { textField in
            
        }
        valueWriteController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        valueWriteController.addAction(UIAlertAction(title: "Write", style: .default) { _ in
            
            if let _text = valueWriteController.textFields?.first?.text {
                self.writeValueForCharacteristic(hexadecimalString: _text, characteristic: characteristic)
            }
            
        })
        self.present(valueWriteController, animated: true, completion: nil)
    }
    
    fileprivate func writeValueForCharacteristic(hexadecimalString: String,characteristic: Characteristic) {
        let hexadecimalData: Data = Data.fromHexString(string: hexadecimalString)
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        characteristic.writeValue(hexadecimalData as Data, type: type)
            .subscribe(onNext: { [weak self] _ in
                self?.characteristicsTableView.reloadData()
            }).addDisposableTo(disposeBag)
    }

    fileprivate func triggerValueRead(for characteristic: Characteristic) {
        characteristic.readValue()
            .subscribe(onNext: { [weak self] _ in
                self?.characteristicsTableView.reloadData()
            }).addDisposableTo(disposeBag)
    }
}

extension CharacteristicsController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characteristicsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: characteristicCellId, for: indexPath)
        let characteristic = characteristicsList[indexPath.row]
        if let cell = cell as? CharacteristicTableViewCell {
            cell.update(with: characteristic)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let characteristic = characteristicsList[indexPath.row]
        let actionSheet = UIAlertController(title: "Choose action", message: nil, preferredStyle: .actionSheet)

        if characteristic.properties.contains(.notify) {
            let turnNotificationOffAction = UIAlertAction(title: "Turn OFF notifications", style: .default) { _ in
                self.setNotificationsState(enabled: false, characteristic: characteristic)
            }
            let turnNotificationOnAction = UIAlertAction(title: "Turn ON notifications", style: .default) { _ in
                self.setNotificationsState(enabled: true, characteristic: characteristic)
            }
            actionSheet.addAction(turnNotificationOffAction)
            actionSheet.addAction(turnNotificationOnAction)
        }
        if characteristic.properties.contains(.read) {
            let readValueNotificationAction = UIAlertAction(title: "Read", style: .default) { _ in
                self.triggerValueRead(for: characteristic)
            }
            actionSheet.addAction(readValueNotificationAction)
        }
        
        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
            let writeValueNotificationAction = UIAlertAction(title: "Write", style: .default) { _ in
                self.showWriteFieldForCharacteristic(characteristic: characteristic)
            }
            actionSheet.addAction(writeValueNotificationAction)
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "CHARACTERISTICS"
    }
}

extension CharacteristicTableViewCell {
    func update(with characteristic: Characteristic) {
        self.UUIDLabel.text = characteristic.uuid.uuidString
        self.isNotifyingLabel.text = characteristic.isNotifying ? "true" : "false"
        self.valueLabel.text = characteristic.value?.hexadecimalString ?? "Empty"
    }
}

