//
//  RxCentralManagerType.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import RxSwift
import CoreBluetooth

/**
 Protocol which wraps Central Manager for bluetooth devices. It is used directly by BluetoothManager
*/
public protocol RxCentralManagerType {

    /// Observable which emits state changes of central manager after subscriptions
    var rx_didUpdateState: Observable<CBCentralManagerState> { get }
    /// Observable which emits elements after subsciption when central manager want to restore its state
    var rx_willRestoreState: Observable<[String:AnyObject]> { get }
    /// Observable which emits peripherals which were discovered after subscription
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String:AnyObject], NSNumber)> { get }
    /// Observable which emits peripherals which were connected after subscription
    var rx_didConnectPeripheral: Observable<RxPeripheralType> { get }
    /// Observable which emits peripherals which failed to connect after subscriptions
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> { get }
    /// Observable which emits peripherals which were disconnected after subscription
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> { get }

    /// Current state of Central Manager
    var state: CBCentralManagerState { get }

    /**
     Start scanning for peripherals with specified services. Results will be available on rx_didDiscoverPeripheral
     observable.

     - parameter serviceUUIDs: Services which peripherals needs to implement. When nil is passed all
                               available peripherals will be discovered.
     - parameter options: Central Manager specific options for scanning
     */
    func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String:AnyObject]?)

    /**
     Connect to specified peripheral. If connection is successful peripheral will be emitted in rx_didConnectPeripheral
     observable. In case of any error it will be emitted on rx_didFailToConnectPeripheral.

     - parameter peripheral: Peripheral to connect to.
     - parameter options: Central Manager specific connection options.
     */
    func connectPeripheral(peripheral: RxPeripheralType, options: [String:AnyObject]?)

    /**
     Cancel peripheral connection. If successful observable rx_didDisconnectPeripheral will emit disconnected
     peripheral with NSError set to nil.

     - parameter peripheral: Peripheral to be disconnected.
     */
    func cancelPeripheralConnection(peripheral: RxPeripheralType)

    /// Abort peripheral scanning
    func stopScan()

    /**
     Retrieve list of connected peripherals which implement specified services. Peripherals which meet criteria
     will be emitted in by returned observable after subscription.

     - parameter serviceUUIDs: List of services which need to be implemented by retrieved peripheral.
     - returns: Observable wich emits connected peripherals.
     */
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]>

    /**
     Retrieve peripherals with specified identifiers.

     - parameter identifiers: List of identifiers of peripherals for which we are looking for.
     - returns: Observable which emits peripherals with specified identifiers.
     */
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]>
}
