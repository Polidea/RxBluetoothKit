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
//        manager = BluetoothManager(centralManager: RxCBCentralManager(queue: dispatch_get_main_queue()))
        
//        let serviceUUID = CBUUID(string: "181d")
//        let characteristicUUID = CBUUID(string: "2a9d")
        
//        manager.scanForDevices([])
//            .delaySubscription(3, scheduler: ConcurrentMainScheduler.instance)
//            .filter { scannedDevice in
//                return scannedDevice.advertisementData.localName == "StandUp_Mat"
//            }
//            .take(1)
//            .flatMap { scannedDevice -> Observable<Peripheral> in
//                let device = scannedDevice.device
//                return device.connect()
//            }
//            .flatMap { connectedDevice -> Observable<Service> in
//                XCGLogger.info("Connected!")
//                return connectedDevice.discoverServices([])
//            }
//            .filter {
//                XCGLogger.info("Found service: \($0.uuid)")
//                return $0.uuid == serviceUUID
//            }
//            .take(1)
//            .flatMap { service -> Observable<Service> in
//                XCGLogger.info("Discovers characteristic for service: \(service.uuid)")
//                return service.discoverCharacteristics([characteristicUUID])
//            }
//            .flatMap { service -> Observable<Characteristic> in
//                XCGLogger.info( "Scanned characteristics: \(service.service.characteristics)")
//                return service.characteristics.toObservable()
//            }
//            .flatMap { characteristic -> Observable<Characteristic> in
//                XCGLogger.info("Setting notify for characteristic: \(characteristic.uuid.UUIDString)")
//                return characteristic.setNotifyValue(true)
//            }
//            .flatMap { characteristic -> Observable<Characteristic> in
//                XCGLogger.info("Observing characteristic: \(characteristic.uuid.UUIDString)")
//                return characteristic.monitorValueUpdate()
//            }
//            .subscribe({ (event) -> Void in
//                switch event {
//                case .Next(let characteristic):
//                    XCGLogger.info("Characteristic: \(characteristic.uuid) value: \(characteristic.value)")
//                case .Completed:
//                    XCGLogger.info("Completed")
//                case .Error(let err):
//                    XCGLogger.info("Error: \(err)")
//                }
//            })
//            .addDisposableTo(disposeBag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

