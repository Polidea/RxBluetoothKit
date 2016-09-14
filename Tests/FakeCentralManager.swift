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
import RxTests
import CoreBluetooth

class FakeCentralManager: RxCentralManagerType {

    var rx_didUpdateState: Observable<BluetoothState> = .never()
    var rx_willRestoreState: Observable<[String:AnyObject]> = .never()
    var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String:AnyObject], NSNumber)> = .never()
    var rx_didConnectPeripheral: Observable<RxPeripheralType> = .never()
    var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> = .never()
    var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> = .never()

    var state: BluetoothState = BluetoothState.PoweredOn

    var scanForPeripheralsWithServicesTO: TestableObserver<([CBUUID]?, [String:AnyObject]?)>?
    func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String:AnyObject]?) {
        scanForPeripheralsWithServicesTO?.onNext((serviceUUIDs, options))
    }
    var connectPeripheralOptionsTO: TestableObserver<(RxPeripheralType, [String:AnyObject]?)>?
    func connectPeripheral(peripheral: RxPeripheralType, options: [String:AnyObject]?) {
        connectPeripheralOptionsTO?.onNext((peripheral, options))
    }
    var cancelPeripheralConnectionTO: TestableObserver<RxPeripheralType>?
    func cancelPeripheralConnection(peripheral: RxPeripheralType) {
        cancelPeripheralConnectionTO?.onNext(peripheral)
    }
    var stopScanTO: TestableObserver<()>?
    func stopScan() {
        stopScanTO?.onNext(())
    }
    var retrieveConnectedPeripheralsWithServicesTO: TestableObserver<[CBUUID]>?
    var retrieveConnectedPeripheralsWithServicesResult: Observable<[RxPeripheralType]> = .never()
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
        retrieveConnectedPeripheralsWithServicesTO?.onNext(serviceUUIDs)
        return retrieveConnectedPeripheralsWithServicesResult
    }
    var retrievePeripheralsWithIdentifiersTO: TestableObserver<[NSUUID]>?
    var retrievePeripheralsWithIdentifiersResult: Observable<[RxPeripheralType]> = .never()
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]> {
        retrievePeripheralsWithIdentifiersTO?.onNext(identifiers)
        return retrievePeripheralsWithIdentifiersResult
    }
}
