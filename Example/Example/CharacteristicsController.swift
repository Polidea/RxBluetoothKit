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

class CharacteristicsController: UIViewController {

    var service: Service!

    private let disposeBag = DisposeBag()

    @IBOutlet weak var characteristicsTableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.hidden = true
        }
    }
    var manager: BluetoothManager!
    private var characteristicsList: [Characteristic] = []
    private let characteristicCellId = "CharacteristicCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        characteristicsTableView.delegate = self
        characteristicsTableView.dataSource = self
        characteristicsTableView.estimatedRowHeight = 40.0
        characteristicsTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getCharacteristicsForService(service)
    }

    private func getCharacteristicsForService(service: Service) {
        service.discoverCharacteristics(nil)
            .subscribeNext { characteristics in
                self.characteristicsList = characteristics

                self.characteristicsTableView.reloadData()
            }.addDisposableTo(disposeBag)
    }

    private func setupCharacterisics(characteristics: [Characteristic]) {

    }
}

extension CharacteristicsController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characteristicsList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(characteristicCellId, forIndexPath: indexPath)
        let characteristic = characteristicsList[indexPath.row]
        if let cell = cell as? CharacteristicTableViewCell {
            cell.UUIDLabel = characteristic.uuid.UUIDString

        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "SERVICES"
    }
}
    


