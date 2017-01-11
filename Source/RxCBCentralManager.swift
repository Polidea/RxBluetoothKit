// The MIT License (MIT)
//
// Copyright (c) 2016 Polidea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import RxSwift
import CoreBluetooth

/**
 Core Bluetooth implementation of RxCentralManagerType. This is a lightweight wrapper which allows
 to hide all implementation details.
 */
class RxCBCentralManager: RxCentralManagerType {

    private let centralManager: CBCentralManager
    private let internalDelegate = InternalDelegate()

    /**
     Create Core Bluetooth implementation of RxCentralManagerType which is used by BluetoothManager class.
     User can specify on which thread all bluetooth events are collected.

     - parameter queue: Dispatch queue on which callbacks are received.
     */
    init(queue: DispatchQueue, options: [String : AnyObject]? = nil) {
        centralManager = CBCentralManager(delegate: internalDelegate, queue: queue, options: options)
    }

    @objc private class InternalDelegate: NSObject, CBCentralManagerDelegate {
        let didUpdateStateSubject = PublishSubject<BluetoothState>()
        let willRestoreStateSubject = PublishSubject<[String: Any]>()
        let didDiscoverPeripheralSubject = PublishSubject<(RxPeripheralType, [String: Any], NSNumber)>()
        let didConnectPerihperalSubject = PublishSubject<RxPeripheralType>()
        let didFailToConnectPeripheralSubject = PublishSubject<(RxPeripheralType, Error?)>()
        let didDisconnectPeripheral = PublishSubject<(RxPeripheralType, Error?)>()

        @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
            guard let bleState = BluetoothState(rawValue: central.state.rawValue) else { return }
            didUpdateStateSubject.onNext(bleState)
        }

        @objc func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
            willRestoreStateSubject.onNext(dict)
        }

        @objc func centralManager(_ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String: Any],
            rssi: NSNumber) {
                didDiscoverPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), advertisementData, rssi))
        }

        @objc func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            didConnectPerihperalSubject.onNext(RxCBPeripheral(peripheral: peripheral))
        }

        @objc func centralManager(_ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?) {
                didFailToConnectPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }

        @objc func centralManager(_ central: CBCentralManager,
            didDisconnectPeripheral peripheral: CBPeripheral,
            error: Error?) {
                didDisconnectPeripheral.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }
    }

    /// Observable which infroms when central manager did change its state
    var rx_didUpdateState: Observable<BluetoothState> {
        return internalDelegate.didUpdateStateSubject
    }
    /// Observable which infroms when central manager is about to restore its state
    var rx_willRestoreState: Observable<[String: Any]> {
        return internalDelegate.willRestoreStateSubject
    }
    /// Observable which infroms when central manage discovered peripheral
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String: Any], NSNumber)> {
        return internalDelegate.didDiscoverPeripheralSubject
    }
    /// Observable which infroms when central manager connected to peripheral
    var rx_didConnectPeripheral: Observable<RxPeripheralType> {
        return internalDelegate.didConnectPerihperalSubject
    }
    /// Observable which infroms when central manager failed to connect to peripheral
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, Error?)> {
        return internalDelegate.didFailToConnectPeripheralSubject
    }
    /// Observable which infroms when central manager disconnected from peripheral
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, Error?)> {
        return internalDelegate.didDisconnectPeripheral
    }

    /// Current central manager state
    var state: BluetoothState {
        return BluetoothState(rawValue: centralManager.state.rawValue) ?? .unsupported
    }

    /**
     Start scanning for peripherals with specified services. Results will be available on rx_didDiscoverPeripheral
     observable.

     - parameter serviceUUIDs: Services which peripherals needs to implement. When nil is passed all
     available peripherals will be discovered.
     - parameter options: Central Manager specific options for scanning
     */
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        return centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }

    /**
     Connect to specified peripheral. If connection is successful peripheral will be emitted in rx_didConnectPeripheral
     observable. In case of any error it will be emitted on rx_didFailToConnectPeripheral.

     - parameter peripheral: Peripheral to connect to.
     - parameter options: Central Manager specific connection options.
     */
    func connect(_ peripheral: RxPeripheralType, options: [String: Any]?) {
        return centralManager.connect((peripheral as! RxCBPeripheral).peripheral, options: options)
    }

    /**
     Cancel peripheral connection. If successful observable rx_didDisconnectPeripheral will emit disconnected
     peripheral with NSError set to nil.

     - parameter peripheral: Peripheral to be disconnected.
     */
    func cancelPeripheralConnection(_ peripheral: RxPeripheralType) {
        return centralManager.cancelPeripheralConnection((peripheral as! RxCBPeripheral).peripheral)
    }

    /// Abort peripheral scanning
    func stopScan() {
        return centralManager.stopScan()
    }

    /**
     Retrieve list of connected peripherals which implement specified services. Peripherals which meet criteria
     will be emitted in by returned observable after subscription.

     - parameter serviceUUIDs: List of services which need to be implemented by retrieved peripheral.
     - returns: Observable wich emits connected peripherals.
     */
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
        return .just(centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs).map {
            RxCBPeripheral(peripheral: $0)
        })
    }

    /**
     Retrieve peripherals with specified identifiers.

     - parameter identifiers: List of identifiers of peripherals for which we are looking for.
     - returns: Observable which emits peripherals with specified identifiers.
     */
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[RxPeripheralType]> {
        return .just(centralManager.retrievePeripherals(withIdentifiers: identifiers).map {
            RxCBPeripheral(peripheral: $0)
        })
    }
}
