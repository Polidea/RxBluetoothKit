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

class RxCBCentralManager: RxCentralManagerType {

    let centralManager: CBCentralManager
    private let internalDelegate = InternalDelegate()

    @available(*, deprecated)
    var objectId: UInt {
        return UInt(bitPattern: ObjectIdentifier(centralManager))
    }

    init(queue: DispatchQueue, options: [String: AnyObject]? = nil) {
        centralManager = CBCentralManager(delegate: internalDelegate, queue: queue, options: options)
    }

    @objc private class InternalDelegate: NSObject, CBCentralManagerDelegate {
        let didUpdateStateSubject = PublishSubject<BluetoothState>()
        let willRestoreStateSubject = ReplaySubject<[String: Any]>.create(bufferSize: 1)
        let didDiscoverPeripheralSubject = PublishSubject<(RxPeripheralType, [String: Any], NSNumber)>()
        let didConnectPerihperalSubject = PublishSubject<RxPeripheralType>()
        let didFailToConnectPeripheralSubject = PublishSubject<(RxPeripheralType, Error?)>()
        let didDisconnectPeripheral = PublishSubject<(RxPeripheralType, Error?)>()

        @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
            guard let bleState = BluetoothState(rawValue: central.state.rawValue) else { return }
            RxBluetoothKitLog.d("\(central.logDescription) didUpdateState(state: \(bleState.logDescription))")
            didUpdateStateSubject.onNext(bleState)
        }

        @objc func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
            RxBluetoothKitLog.d("\(central.logDescription) willRestoreState(restoredState: \(dict))")
            willRestoreStateSubject.onNext(dict)
        }

        @objc func centralManager(_ central: CBCentralManager,
                                  didDiscover peripheral: CBPeripheral,
                                  advertisementData: [String: Any],
                                  rssi: NSNumber) {
            RxBluetoothKitLog.d("""
                                \(central.logDescription) didDiscover(peripheral: \(peripheral.logDescription),
                                rssi: \(rssi))
                                """)
            didDiscoverPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), advertisementData, rssi))
        }

        @objc func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            didConnectPerihperalSubject.onNext(RxCBPeripheral(peripheral: peripheral))
        }

        @objc func centralManager(_ central: CBCentralManager,
                                  didFailToConnect peripheral: CBPeripheral,
                                  error: Error?) {
            RxBluetoothKitLog.d("""
                                \(central.logDescription) didFailToConnect(to: \(peripheral.logDescription),
                                error: \(String(describing: error)))
                                """)
            didFailToConnectPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }

        @objc func centralManager(_ central: CBCentralManager,
                                  didDisconnectPeripheral peripheral: CBPeripheral,
                                  error: Error?) {
            RxBluetoothKitLog.d("""
                                \(central.logDescription) didDisconnect(from: \(peripheral.logDescription),
                                error: \(String(describing: error)))
                                """)
            didDisconnectPeripheral.onNext((RxCBPeripheral(peripheral: peripheral), error))
        }
    }

    var rx_didUpdateState: Observable<BluetoothState> {
        return internalDelegate.didUpdateStateSubject
    }

    var rx_willRestoreState: Observable<[String: Any]> {
        return internalDelegate.willRestoreStateSubject
    }

    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String: Any], NSNumber)> {
        return internalDelegate.didDiscoverPeripheralSubject
    }

    var rx_didConnectPeripheral: Observable<RxPeripheralType> {
        return internalDelegate.didConnectPerihperalSubject
    }

    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, Error?)> {
        return internalDelegate.didFailToConnectPeripheralSubject
    }

    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, Error?)> {
        return internalDelegate.didDisconnectPeripheral
    }

    var state: BluetoothState {
        return BluetoothState(rawValue: centralManager.state.rawValue) ?? .unsupported
    }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        return centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }

    func connect(_ peripheral: RxPeripheralType, options: [String: Any]?) {
        return centralManager.connect((peripheral as! RxCBPeripheral).peripheral, options: options)
    }

    func cancelPeripheralConnection(_ peripheral: RxPeripheralType) {
        return centralManager.cancelPeripheralConnection((peripheral as! RxCBPeripheral).peripheral)
    }

    func stopScan() {
        return centralManager.stopScan()
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
        return .just(centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs).map(RxCBPeripheral.init))
    }

    /// Retrieve peripherals with specified identifiers.
    ///
    /// - parameter identifiers: List of identifiers of peripherals for which we are looking for.
    /// - returns: `Observable` which emits peripherals with specified identifiers.
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[RxPeripheralType]> {
        return .just(centralManager.retrievePeripherals(withIdentifiers: identifiers).map(RxCBPeripheral.init))
    }
}
