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
        manager = BluetoothManager(centralManager: RxCBCentralManager(queue: dispatch_get_main_queue()))
        
        let serviceUUID = CBUUID(string: "180a")
        let characteristicUUID = CBUUID(string: "2a9d")
        
        manager.scanForPeripherals(nil)
            .delaySubscription(3, scheduler: ConcurrentMainScheduler.instance)
            .filter { scannedDevice in
                print("found device : \(scannedDevice.advertisementData.localName)")
                return scannedDevice.advertisementData.localName == "StandUp_Mat"
            }
            .take(1)
            .flatMap { scannedDevice -> Observable<Peripheral> in
                let peripheral = scannedDevice.peripheral
                print("connecting to device: \(unsafeAddressOf(peripheral))")
                return peripheral.connect()
            }
            .flatMap { connectedDevice -> Observable<Service> in
                print("Discovering services: \(unsafeAddressOf(connectedDevice))")
                return Observable.from(connectedDevice.discoverServices([]))
            }
            .filter {
                print("Found service: \($0.uuid)")
                return $0.uuid == serviceUUID
            }
            .take(1)
            .flatMap { service -> Observable<Characteristic> in
                print("Discovers characteristic for service: \(service.uuid)")
                return Observable.from(service.discoverCharacteristics([characteristicUUID]))
            }
            .flatMap { characteristic -> Observable<Characteristic> in
                print("Read characteristic: \(characteristic.uuid.UUIDString)")
                return characteristic.readValue()
            }
            /*
            .flatMap { characteristic -> Observable<Characteristic> in
                print("Setting notify for characteristic: \(characteristic.uuid.UUIDString)")
                return characteristic.setNotifyValue(true)
            }
            .flatMap { characteristic -> Observable<Characteristic> in
                print("Observing characteristic: \(characteristic.uuid.UUIDString)")
                return characteristic.monitorValueUpdate()
            }
            */
            .subscribe({ (event) -> Void in
                switch event {
                case .Next(let characteristic):
                    print("Characteristic: \(characteristic.uuid) value: \(characteristic.value)")
                case .Completed:
                    print("Completed")
                case .Error(let err):
                    print("Error: \(err)")
                }
            })
            .addDisposableTo(disposeBag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

