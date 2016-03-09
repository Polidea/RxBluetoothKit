//
//  RxCBCentralManager.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import RxSwift
import CoreBluetooth

public class RxCBCentralManager: RxCentralManagerType {
    private let centralManager: CBCentralManager
    private let internalDelegate = InternalDelegate()

    public init(queue: dispatch_queue_t) {
        centralManager = CBCentralManager(delegate: internalDelegate, queue: queue)
    }

    @objc private class InternalDelegate: NSObject, CBCentralManagerDelegate {
        let didUpdateStateSubject = PublishSubject<CBCentralManagerState>()
        let willRestoreStateSubject = PublishSubject<[String:AnyObject]>()
        let didDiscoverPeripheralSubject = PublishSubject<(RxPeripheralType, [String:AnyObject], NSNumber)>()
        let didConnectPerihperalSubject = PublishSubject<RxPeripheralType>()
        let didFailToConnectPeripheralSubject = PublishSubject<(RxPeripheralType, NSError?)>()
        let didDisconnectPeripheral = PublishSubject<(RxPeripheralType, NSError?)>()

        @objc func centralManagerDidUpdateState(central: CBCentralManager) {
            didUpdateStateSubject.onNext(central.state)
        }

        @objc func centralManager(central: CBCentralManager, willRestoreState dict: [String:AnyObject]) {
            willRestoreStateSubject.onNext(dict)
        }

        @objc func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String:AnyObject], RSSI: NSNumber) {
            didDiscoverPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), advertisementData, RSSI))
        }

        @objc func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
            didConnectPerihperalSubject.onNext(RxCBPeripheral(peripheral: peripheral))
        }

        @objc func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
            didFailToConnectPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }

        @objc func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
            didDisconnectPeripheral.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }
    }

    public var rx_didUpdateState: Observable<CBCentralManagerState> {
        return internalDelegate.didUpdateStateSubject
    }
    public var rx_willRestoreState: Observable<[String:AnyObject]> {
        return internalDelegate.willRestoreStateSubject
    }
    public var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String:AnyObject], NSNumber)> {
        return internalDelegate.didDiscoverPeripheralSubject
    }
    public var rx_didConnectPeripheral: Observable<RxPeripheralType> {
        return internalDelegate.didConnectPerihperalSubject
    }
    public var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> {
        return internalDelegate.didFailToConnectPeripheralSubject
    }
    public var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> {
        return internalDelegate.didDisconnectPeripheral
    }

    public var state: CBCentralManagerState {
        return centralManager.state
    }

    public func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String:AnyObject]?) {
        return centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: options)
    }

    public func connectPeripheral(peripheral: RxPeripheralType, options: [String:AnyObject]?) {
        return centralManager.connectPeripheral((peripheral as! RxCBPeripheral).peripheral, options: options)
    }

    public func cancelPeripheralConnection(peripheral: RxPeripheralType) {
        return centralManager.cancelPeripheralConnection((peripheral as! RxCBPeripheral).peripheral)
    }

    public func stopScan() {
        return centralManager.stopScan()
    }

    public func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
        return Observable.just(centralManager.retrieveConnectedPeripheralsWithServices(serviceUUIDs).map {
            RxCBPeripheral(peripheral: $0)
        })
    }

    public func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]> {
        return Observable.just(centralManager.retrievePeripheralsWithIdentifiers(identifiers).map {
            RxCBPeripheral(peripheral: $0)
        })
    }
}