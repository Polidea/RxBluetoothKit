//
//  ViewController.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 02/24/2016.
//  Copyright (c) 2016 Przemysław Lenart. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth
import RxBluetoothKit

class ViewController: UIViewController {

    
    var disposeBag = DisposeBag()
    var manager : BluetoothManager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

