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
 Protocol which wraps Central Manager for bluetooth devices. It is used directly by BluetoothManager
*/
protocol RxCentralManagerType {

    /// Observable which emits state changes of central manager after subscriptions
    var rx_didUpdateState: Observable<BluetoothState> { get }
    /// Observable which emits elements after subsciption when central manager want to restore its state
    var rx_willRestoreState: Observable<[String:Any]> { get }
    /// Observable which emits peripherals which were discovered after subscription
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String:Any], NSNumber)> { get }
    /// Observable which emits peripherals which were connected after subscription
    var rx_didConnectPeripheral: Observable<RxPeripheralType> { get }
    /// Observable which emits peripherals which failed to connect after subscriptions
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, Error?)> { get }
    /// Observable which emits peripherals which were disconnected after subscription
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, Error?)> { get }

    /// Current state of Central Manager
    var state: BluetoothState { get }

    /**
     Start scanning for peripherals with specified services. Results will be available on rx_didDiscoverPeripheral
     observable.

     - parameter serviceUUIDs: Services which peripherals needs to implement. When nil is passed all
                               available peripherals will be discovered.
     - parameter options: Central Manager specific options for scanning
     */
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String:Any]?)

    /**
     Connect to specified peripheral. If connection is successful peripheral will be emitted in rx_didConnectPeripheral
     observable. In case of any error it will be emitted on rx_didFailToConnectPeripheral.

     - parameter peripheral: Peripheral to connect to.
     - parameter options: Central Manager specific connection options.
     */
    func connect(_ peripheral: RxPeripheralType, options: [String:Any]?)

    /**
     Cancel peripheral connection. If successful observable rx_didDisconnectPeripheral will emit disconnected
     peripheral with NSError set to nil.

     - parameter peripheral: Peripheral to be disconnected.
     */
    func cancelPeripheralConnection(_ peripheral: RxPeripheralType)

    /// Abort peripheral scanning
    func stopScan()

    /**
     Retrieve list of connected peripherals which implement specified services. Peripherals which meet criteria
     will be emitted in by returned observable after subscription.

     - parameter serviceUUIDs: List of services which need to be implemented by retrieved peripheral.
     - returns: Observable wich emits connected peripherals.
     */
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]>

    /**
     Retrieve peripherals with specified identifiers.

     - parameter identifiers: List of identifiers of peripherals for which we are looking for.
     - returns: Observable which emits peripherals with specified identifiers.
     */
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[RxPeripheralType]>
}
