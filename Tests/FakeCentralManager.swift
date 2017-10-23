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

@testable
import RxBluetoothKit
import RxSwift
import RxTest
import CoreBluetooth

class FakeCentralManager: RxCentralManagerType {

    var objectId: UInt = 0
    var rx_didUpdateState: Observable<BluetoothState> = .never()
    var rx_willRestoreState: Observable<[String: Any]> = .never()
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String: Any], NSNumber)> = .never()
    var rx_didConnectPeripheral: Observable<RxPeripheralType> = .never()
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, Error?)> = .never()
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, Error?)> = .never()

    var state: BluetoothState = BluetoothState.poweredOn

    var centralManager: CBCentralManager {
        fatalError("Central manager not available")
    }

    var scanForPeripheralsWithServicesTO: TestableObserver<([CBUUID]?, [String: Any]?)>?
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanForPeripheralsWithServicesTO?.onNext((serviceUUIDs, options))
    }

    var connectPeripheralOptionsTO: TestableObserver<(RxPeripheralType, [String: Any]?)>?
    func connect(_ peripheral: RxPeripheralType, options: [String: Any]?) {
        connectPeripheralOptionsTO?.onNext((peripheral, options))
    }

    var cancelPeripheralConnectionTO: TestableObserver<RxPeripheralType>?
    func cancelPeripheralConnection(_ peripheral: RxPeripheralType) {
        cancelPeripheralConnectionTO?.onNext(peripheral)
    }

    var stopScanTO: TestableObserver<()>?
    func stopScan() {
        stopScanTO?.onNext(())
    }

    var retrieveConnectedPeripheralsWithServicesTO: TestableObserver<[CBUUID]>?
    var retrieveConnectedPeripheralsWithServicesResult: Observable<[RxPeripheralType]> = .never()
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
        retrieveConnectedPeripheralsWithServicesTO?.onNext(serviceUUIDs)
        return retrieveConnectedPeripheralsWithServicesResult
    }

    var retrievePeripheralsWithIdentifiersTO: TestableObserver<[UUID]>?
    var retrievePeripheralsWithIdentifiersResult: Observable<[RxPeripheralType]> = .never()
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[RxPeripheralType]> {
        retrievePeripheralsWithIdentifiersTO?.onNext(identifiers)
        return retrievePeripheralsWithIdentifiersResult
    }
}
