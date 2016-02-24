//
//  RxCentralManagerType.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import RxSwift
import CoreBluetooth

public protocol RxCentralManagerType {
    
    var rx_didUpdateState: Observable<CBCentralManagerState> { get }
    var rx_willRestoreState: Observable<[String : AnyObject]> { get }
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String : AnyObject], NSNumber)> { get }
    var rx_didConnectPeripheral: Observable<RxPeripheralType> { get }
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> { get }
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> { get }
    
    var state: CBCentralManagerState { get }
    
    func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String : AnyObject]?)
    func connectPeripheral(peripheral: RxPeripheralType, options: [String : AnyObject]?)
    func cancelPeripheralConnection(peripheral: RxPeripheralType)
    func stopScan()
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID])  -> Observable<[RxPeripheralType]>
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]>
    
}