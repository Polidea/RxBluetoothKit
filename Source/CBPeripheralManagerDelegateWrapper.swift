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
import RxSwift

@objc class CBPeripheralManagerDelegateWrapper: NSObject, CBPeripheralManagerDelegate {

    var rx_didUpdateState: Observable<BluetoothState> {
        return didUpdateStateSubject
    }

    var rx_willRestoreState: Observable<[String: Any]> {
        return willRestoreStateSubject
    }

    var rx_didStartAdvertising: Observable<Error?> {
        return didStartAdvertisingSubject
    }

    var rx_didAddService: Observable<Error?> {
        return didAddServiceSubject
    }

    var rx_didSubscribeToCharacteristic: Observable<(CBCentral, CBCharacteristic)> {
        return didSubscribeToCharacteristicSubject
    }

    var rx_didUnsubscribeFromCharacteristic: Observable<(CBCentral, CBCharacteristic)> {
        return didUnsubscribeFromCharacteristicSubject
    }

    var rx_didAddReceiveRead: Observable<CBATTRequest> {
        return didReceiveReadSubject
    }

    var rx_didReceiveWrite: Observable<[CBATTRequest]> {
        return didReceiveWriteSubject
    }

    var rx_isReadyToUpdateSubscribers: Observable<Void> {
        return isReadyToUpdateSubscribersSubject
    }

    private let didUpdateStateSubject = PublishSubject<BluetoothState>()
    private let willRestoreStateSubject = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    private let didStartAdvertisingSubject = PublishSubject<Error?>()
    private let didAddServiceSubject = PublishSubject<Error?>()
    private let didSubscribeToCharacteristicSubject = PublishSubject<(CBCentral, CBCharacteristic)>()
    private let didUnsubscribeFromCharacteristicSubject = PublishSubject<(CBCentral, CBCharacteristic)>()
    private let didReceiveReadSubject = PublishSubject<CBATTRequest>()
    private let didReceiveWriteSubject = PublishSubject<[CBATTRequest]>()
    private let isReadyToUpdateSubscribersSubject = PublishSubject<Void>()

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard let bleState = BluetoothState(rawValue: peripheral.state.rawValue) else { return }
        RxBluetoothKitLog.d("\(peripheral.logDescription) didUpdateState(state: \(bleState.logDescription))")
        didUpdateStateSubject.onNext(bleState)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        RxBluetoothKitLog.d("\(peripheral.logDescription) willRestoreState(restoredState: \(dict))")
        willRestoreStateSubject.onNext(dict)
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription) didStartAdvertising
                            (error: \(String(describing: error))")
                            """)
        didStartAdvertisingSubject.onNext(error)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription) didAddService: \(service.logDescription)
                            (error: \(String(describing: error))")
                            """)
        didAddServiceSubject.onNext(error)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
        ) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription) central: \(central)
                            didSubscribeTo: \(characteristic.logDescription)
                            """)
        didSubscribeToCharacteristicSubject.onNext((central, characteristic))
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
        ) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription) central: \(central)
                            didSubscribeTo: \(characteristic.logDescription)
                            """)
        didUnsubscribeFromCharacteristicSubject.onNext((central, characteristic))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription)
                            didReceiveRead: \(request.logDescription)
                            """)
        didReceiveReadSubject.onNext(request)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite request: [CBATTRequest]) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription)
                            didReceiveWriteRequest: \(request.logDescription)
                            """)
        didReceiveWriteSubject.onNext(request)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        RxBluetoothKitLog.d("""
                            \(peripheral.logDescription)
                            isReadyToUpdateSubscribers:
                            """)
        isReadyToUpdateSubscribersSubject.onNext(())
    }
}
