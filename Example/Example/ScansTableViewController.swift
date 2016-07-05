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
    private var peripheralsArray: [ScannedPeripheral] = []
    private var scheduler: ConcurrentDispatchQueueScheduler!
    private let manager = BluetoothManager(queue: dispatch_get_main_queue())
    private var scanningDisposable: Disposable?
    private let scannedPeripheralCellIdentifier = "peripheralCellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        let timerQueue = dispatch_queue_create("com.polidea.rxbluetoothkit.timer", nil)
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
        .flatMap { _ in self.manager.scanForPeripherals(nil, options:nil) }
        .subscribeOn(MainScheduler.instance)
        .subscribe(onNext: {
            self.addNewScannedPeripheral($0)
            }, onError: { error in
        })
    }

    private func addNewScannedPeripheral(peripheral: ScannedPeripheral) {
        let mapped = peripheralsArray.map { $0.peripheral }
        if let indx = mapped.indexOf(peripheral.peripheral) {
            peripheralsArray[indx] = peripheral
        } else {
            self.peripheralsArray.append(peripheral)
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.scansTableView.reloadData()
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier, let cell = sender as? UITableViewCell
            where identifier == "PresentPeripheralDetails" else { return }
        guard let navigationVC = segue.destinationViewController as? UINavigationController,
        let peripheralDetails = navigationVC.topViewController as? PeripheralServicesViewController else { return }

        if let indexPath = scansTableView.indexPathForCell(cell) {
            peripheralDetails.scannedPeripheral = peripheralsArray[indexPath.row]
            peripheralDetails.manager = manager
        }
    }

    @IBAction func scanButtonClicked(sender: UIButton) {
        if isScanInProgress {
            stopScanning()
            sender.setTitle("Start scanning", forState: .Normal)
        } else {
            startScanning()
            sender.setTitle("Stop scanning", forState: .Normal)
        }
    }
}

extension ScansTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(scannedPeripheralCellIdentifier, forIndexPath: indexPath)
        let peripheral = peripheralsArray[indexPath.row]
        if let peripheralCell = cell as? ScannedPeripheralCell {
            peripheralCell.configureWithScannedPeripheral(peripheral)
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
    func configureWithScannedPeripheral(peripheral: ScannedPeripheral) {
        RSSILabel.text = peripheral.RSSI.stringValue
        peripheralNameLabel.text = peripheral.advertisementData.localName ?? peripheral.peripheral.identifier.UUIDString

        //TODO: Pretty print it ;) nsattributed string maybe.
        advertismentDataLabel.text = "\(peripheral.advertisementData.advertisementData)"
    }
}

