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

class PeripheralDetailsViewController: UIViewController {

    private let disposeBag = DisposeBag()

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.hidden = true
        }
    }
    @IBOutlet weak var connectionStateLabel: UILabel!

    var scannedPeripheral: ScannedPeripheral!
    var manager: BluetoothManager!
    var connectedPeripheral: Peripheral?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        manager.connectToPeripheral(scannedPeripheral.peripheral)
            .subscribe(onNext: {
                self.connectedPeripheral = $0
                }, onError: { error in
            }).addDisposableTo(disposeBag)
        activityIndicatorView.hidden = false
        activityIndicatorView.startAnimating()
    }
}
