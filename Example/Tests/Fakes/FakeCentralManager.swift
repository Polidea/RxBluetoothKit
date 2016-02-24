//
//  FakeCentralManager.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 24/02/16.
//

import Foundation

import RxBluetoothKit
import RxSwift
import RxTests
import CoreBluetooth

class FakeCentralManager: RxCentralManagerType {
    
    var rx_didUpdateState: Observable<CBCentralManagerState> = Observable.never()
    var rx_willRestoreState: Observable<[String : AnyObject]> = Observable.never()
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String : AnyObject], NSNumber)> = Observable.never()
    var rx_didConnectPeripheral: Observable<RxPeripheralType> = Observable.never()
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> = Observable.never()
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> = Observable.never()
    
    var state: CBCentralManagerState = CBCentralManagerState.PoweredOn
    
    var scanForPeripheralsWithServicesTO : TestableObserver<([CBUUID]?, [String:AnyObject]?)>?
    func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String : AnyObject]?) {
        scanForPeripheralsWithServicesTO?.onNext((serviceUUIDs, options))
    }
    var connectPeripheralOptionsTO : TestableObserver<(RxPeripheralType, [String: AnyObject]?)>?
    func connectPeripheral(peripheral: RxPeripheralType, options: [String : AnyObject]?) {
        connectPeripheralOptionsTO?.onNext((peripheral, options))
    }
    var cancelPeripheralConnectionTO : TestableObserver<RxPeripheralType>?
    func cancelPeripheralConnection(peripheral: RxPeripheralType) {
        cancelPeripheralConnectionTO?.onNext(peripheral)
    }
    var stopScanTO : TestableObserver<()>?
    func stopScan() {
        stopScanTO?.onNext(())
    }
    var retrieveConnectedPeripheralsWithServicesTO : TestableObserver<[CBUUID]>?
    var retrieveConnectedPeripheralsWithServicesResult : Observable<[RxPeripheralType]> = .never()
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID])  -> Observable<[RxPeripheralType]> {
        retrieveConnectedPeripheralsWithServicesTO?.onNext(serviceUUIDs)
        return retrieveConnectedPeripheralsWithServicesResult
    }
    var retrievePeripheralsWithIdentifiersTO : TestableObserver<[NSUUID]>?
    var retrievePeripheralsWithIdentifiersResult : Observable<[RxPeripheralType]> = .never()
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]> {
        retrievePeripheralsWithIdentifiersTO?.onNext(identifiers)
        return retrievePeripheralsWithIdentifiersResult
    }
}