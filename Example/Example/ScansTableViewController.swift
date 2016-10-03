//
//  ScansTableViewController.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 29.03.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import CoreBluetooth

class ScansTableViewController: UIViewController {

    @IBOutlet weak var scansTableView: UITableView!

    private var isScanInProgress = false
    private var scheduler: ConcurrentDispatchQueueScheduler!
    private let manager = BluetoothManager(queue: .main)
    private var scanningDisposable: Disposable?
    fileprivate var peripheralsArray: [ScannedPeripheral] = []
    fileprivate let scannedPeripheralCellIdentifier = "peripheralCellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        let timerQueue = DispatchQueue(label: "com.polidea.rxbluetoothkit.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
        scansTableView.delegate = self
        scansTableView.dataSource = self
        scansTableView.estimatedRowHeight = 80.0
        scansTableView.rowHeight = UITableViewAutomaticDimension
    }

    private func stopScanning() {
        scanningDisposable?.dispose()
        isScanInProgress = false
        self.title = ""
    }

    private func startScanning() {
        isScanInProgress = true
        self.title = "Scanning..."
        scanningDisposable = manager.rx_state
        .timeout(4.0, scheduler: scheduler)
        .take(1)
        .flatMap { _ in self.manager.scanForPeripherals(withServices: nil, options:nil) }
        .subscribeOn(MainScheduler.instance)
        .subscribe(onNext: {
            self.addNewScannedPeripheral($0)
            }, onError: { error in
        })
    }


    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        let mapped = peripheralsArray.map { $0.peripheral }
        if let indx = mapped.index(of: peripheral.peripheral) {
            peripheralsArray[indx] = peripheral
        } else {
            self.peripheralsArray.append(peripheral)
        }
        DispatchQueue.main.async {
            self.scansTableView.reloadData()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let cell = sender as? UITableViewCell,
            identifier == "PresentPeripheralDetails" else { return }
        guard let navigationVC = segue.destination as? UINavigationController,
            let peripheralDetails = navigationVC.topViewController as? PeripheralServicesViewController else { return }

        if let indexPath = scansTableView.indexPath(for: cell) {
            peripheralDetails.scannedPeripheral = peripheralsArray[indexPath.row]
            peripheralDetails.manager = manager
        }
    }

    @IBAction func scanButtonClicked(sender: UIButton) {
        if isScanInProgress {
            stopScanning()
            sender.setTitle("Start scanning", for: .normal)
        } else {
            startScanning()
            sender.setTitle("Stop scanning", for: .normal)
        }
    }
}

extension ScansTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: scannedPeripheralCellIdentifier, for: indexPath)
        let peripheral = peripheralsArray[indexPath.row]
        if let peripheralCell = cell as? ScannedPeripheralCell {
            peripheralCell.configure(with: peripheral)
        }
        return cell
    }
}

extension ScansTableViewController: UISplitViewControllerDelegate {

    func splitViewController(splitViewController: UISplitViewController,
                             collapseSecondaryViewController secondaryViewController:UIViewController,
                             ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        //TODO: Check how this works on both devices.
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? PeripheralServicesViewController else { return false }
        if topAsDetailController.scannedPeripheral == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
}

extension ScannedPeripheralCell {
    func configure(with peripheral: ScannedPeripheral) {
        RSSILabel.text = peripheral.rssi.stringValue
        peripheralNameLabel.text = peripheral.advertisementData.localName ?? peripheral.peripheral.identifier.uuidString

        //TODO: Pretty print it ;) nsattributed string maybe.
        advertismentDataLabel.text = "\(peripheral.advertisementData.advertisementData)"
    }
}

