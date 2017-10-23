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

protocol RxCentralManagerType {

    @available(*, deprecated)
    var objectId: UInt { get }

    /// `Observable` which emits state changes of central manager after subscriptions
    var rx_didUpdateState: Observable<BluetoothState> { get }
    /// `Observable` which emits elements after subsciption when central manager want to restore its state
    var rx_willRestoreState: Observable<[String: Any]> { get }
    /// `Observable` which emits peripherals which were discovered after subscription
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String: Any], NSNumber)> { get }
    /// `Observable` which emits peripherals which were connected after subscription
    var rx_didConnectPeripheral: Observable<RxPeripheralType> { get }
    /// `Observable` which emits peripherals which failed to connect after subscriptions
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, Error?)> { get }
    /// `Observable` which emits peripherals which were disconnected after subscription
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, Error?)> { get }
    var state: BluetoothState { get }
    var centralManager: CBCentralManager { get }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func connect(_ peripheral: RxPeripheralType, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: RxPeripheralType)
    func stopScan()
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]>
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[RxPeripheralType]>
}
