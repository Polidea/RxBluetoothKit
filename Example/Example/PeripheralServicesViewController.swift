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
            activityIndicatorView.isHidden = true
        }
    }
    @IBOutlet weak var connectionStateLabel: UILabel!

    var scannedPeripheral: ScannedPeripheral!
    var manager: BluetoothManager!
    private var connectedPeripheral: Peripheral?
    fileprivate var servicesList: [Service] = []
    fileprivate let serviceCellId = "ServiceCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        servicesTableView.delegate = self
        servicesTableView.dataSource = self
        servicesTableView.estimatedRowHeight = 40.0
        servicesTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard scannedPeripheral != nil else { return }
        title = "Connecting"
        manager.connect(scannedPeripheral.peripheral)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.title = "Connected"
                self.activityIndicatorView.stopAnimating()
                self.connectedPeripheral = $0
                self.monitorDisconnection(for: $0)
                self.downloadServices(for: $0)
                }, onError: { [weak self] error in
                    self?.activityIndicatorView.stopAnimating()
            }).addDisposableTo(disposeBag)
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    private func monitorDisconnection(for peripheral: Peripheral) {
        manager.monitorDisconnection(for: peripheral)
            .subscribe(onNext: { [weak self] (peripheral) in
                let alert = UIAlertController(title: "Disconnected!", message: "Peripheral Disconnected", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
        }).addDisposableTo(disposeBag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let cell = sender as? UITableViewCell,
            identifier == "PresentCharacteristics" else { return }
        guard let characteristicsVc = segue.destination as? CharacteristicsController else { return }

        if let indexPath = servicesTableView.indexPath(for: cell) {
            characteristicsVc.service = servicesList[indexPath.row]
        }
    }

    private func downloadServices(for peripheral: Peripheral) {
        peripheral.discoverServices(nil)
            .subscribe(onNext: { services in
                self.servicesList = services
                self.servicesTableView.reloadData()
            }).addDisposableTo(disposeBag)
    }
}

extension PeripheralServicesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servicesList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: serviceCellId, for: indexPath)
        let service = servicesList[indexPath.row]
        if let cell = cell as? ServiceTableViewCell {
            cell.update(with: service)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "SERVICES"
    }
}

extension ServiceTableViewCell {
    func update(with service: Service) {
        self.isPrimaryLabel.text = service.isPrimary ? "True" : "False"
        self.uuidLabel.text = service.uuid.uuidString
    }
}
