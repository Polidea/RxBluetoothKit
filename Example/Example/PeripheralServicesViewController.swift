//
//  PeripheralDetailsViewController.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 29.03.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift

class PeripheralServicesViewController: UIViewController {

    private let disposeBag = DisposeBag()

    @IBOutlet weak var servicesTableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.hidden = true
        }
    }
    @IBOutlet weak var connectionStateLabel: UILabel!

    var scannedPeripheral: ScannedPeripheral!
    var manager: BluetoothManager!
    private var connectedPeripheral: Peripheral?
    private var servicesList: [Service] = []
    private let serviceCellId = "ServiceCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        servicesTableView.delegate = self
        servicesTableView.dataSource = self
        servicesTableView.estimatedRowHeight = 40.0
        servicesTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = "Connecting"
        manager.connectToPeripheral(scannedPeripheral.peripheral)
            .subscribe(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.title = "Connected"
                strongSelf.activityIndicatorView.stopAnimating()
                strongSelf.connectedPeripheral = $0
                strongSelf.monitorDisconnectionOfPeripheral($0)
                strongSelf.downloadServicesOfPeripheral($0)
                }, onError: { [weak self] error in
                    self?.activityIndicatorView.stopAnimating()
            }).addDisposableTo(disposeBag)
        activityIndicatorView.hidden = false
        activityIndicatorView.startAnimating()
    }

    private func monitorDisconnectionOfPeripheral(peripheral: Peripheral) {
        manager.monitorPeripheralDisconnection(peripheral)
            .subscribeNext { [weak self] (peripheral) in
                let alert = UIAlertController(title: "Disconnected!", message: "Peripheral Disconnected", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self?.presentViewController(alert, animated: true, completion: nil)
        }.addDisposableTo(disposeBag)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier, let cell = sender as? UITableViewCell
            where identifier == "PresentCharacteristics" else { return }
        guard let characteristicsVc = segue.destinationViewController as? CharacteristicsController else { return }

        if let indexPath = servicesTableView.indexPathForCell(cell) {
            characteristicsVc.service = servicesList[indexPath.row]
        }
    }

    private func downloadServicesOfPeripheral(peripheral: Peripheral) {
        peripheral.discoverServices(nil)
            .subscribeNext { services in
                self.servicesList = services
                self.servicesTableView.reloadData()
            }.addDisposableTo(disposeBag)
    }
}

extension PeripheralServicesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servicesList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(serviceCellId, forIndexPath: indexPath)
        let service = servicesList[indexPath.row]
        if let cell = cell as? ServiceTableViewCell {
            cell.updateWithService(service)
        }
        return cell
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "SERVICES"
    }
}

extension ServiceTableViewCell {
    func updateWithService(service: Service) {
        self.isPrimaryLabel.text = service.isPrimary ? "True" : "False"
        self.uuidLabel.text = service.UUID.UUIDString
    }
}
