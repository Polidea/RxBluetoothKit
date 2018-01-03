// The MIT License (MIT)
//
// Copyright (c) 2017 Polidea
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
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

@objc class _CBCentralManagerDelegateWrapper: NSObject, _CBCentralManagerDelegate {

    let didUpdateState = PublishSubject<BluetoothState>()
    let willRestoreState = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    let didDiscoverPeripheral = PublishSubject<(CBPeripheralMock, [String: Any], NSNumber)>()
    let didConnectPeripheral = PublishSubject<CBPeripheralMock>()
    let didFailToConnectPeripheral = PublishSubject<(CBPeripheralMock, Error?)>()
    let didDisconnectPeripheral = PublishSubject<(CBPeripheralMock, Error?)>()

    @objc func centralManagerDidUpdateState(_ central: CBCentralManagerMock) {
        guard let bleState = BluetoothState(rawValue: central.state.rawValue) else { return }
        RxBluetoothKitLog.d("\(central.logDescription) didUpdateState(state: \(bleState.logDescription))")
        didUpdateState.onNext(bleState)
    }

    @objc func centralManager(_ central: CBCentralManagerMock, willRestoreState dict: [String: Any]) {
        RxBluetoothKitLog.d("\(central.logDescription) willRestoreState(restoredState: \(dict))")
        willRestoreState.onNext(dict)
    }

    @objc func centralManager(_ central: CBCentralManagerMock,
                              didDiscover peripheral: CBPeripheralMock,
                              advertisementData: [String: Any],
                              rssi: NSNumber) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didDiscover(peripheral: \(peripheral.logDescription),
            rssi: \(rssi))
            """)
        didDiscoverPeripheral.onNext((peripheral, advertisementData, rssi))
    }

    @objc func centralManager(_ central: CBCentralManagerMock, didConnect peripheral: CBPeripheralMock) {
        didConnectPeripheral.onNext(peripheral)
    }

    @objc func centralManager(_ central: CBCentralManagerMock,
                              didFailToConnect peripheral: CBPeripheralMock,
                              error: Error?) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didFailToConnect(to: \(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        didFailToConnectPeripheral.onNext((peripheral, error))
    }

    @objc func centralManager(_ central: CBCentralManagerMock,
                              didDisconnectPeripheral peripheral: CBPeripheralMock,
                              error: Error?) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didDisconnect(from: \(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        didDisconnectPeripheral.onNext((peripheral, error))
    }
}
