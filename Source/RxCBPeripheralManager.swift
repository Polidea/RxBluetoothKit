//
//  RxCBPeripheralManager.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

class RxCBPeripheralManager: RxPeripheralManagerType {
    private let peripheralManager: CBPeripheralManager
    private let internalDelegate = InternalDelegate()
    
    init() {}
}

extension RxCBPeripheralManager {
    
    private class InternalDelegate: NSObject, CBPeripheralManagerDelegate {
        let didUpdateStateSubject = PublishSubject<CBPeripheralManagerState>()
        let willRestoreStateSubject = PublishSubject<[String: AnyObject]>()
        let didStartAdvertisingSubject = PublishSubject<NSError?>()
        let didAddServiceSubject = PublishSubject<(Service, NSError?)>()
        let didSubscribeToCharacteristicSubject = PublishSubject<(Central, Characteristic)>()
        let didUnsubscribeFromCharacteristicSubject = PublishSubject<(Central, Characteristic)>()
        let didRecieveReadRequestSubject = PublishSubject<Request>()
        let didRecieveWriteRequestsSubject = PublishSubject<[Request]>()
        let readyToUpdateSubscribersSubject = PublishSubject<Void>()
        
        @objc func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
            didUpdateStateSubject.onNext(peripheral.state)
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
            willRestoreStateSubject.onNext(dict)
        }
        
        @objc func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
            didStartAdvertisingSubject.onNext(error)
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
            didAddServiceSubject.onNext((Service(peripheral: <#T##Peripheral#>, service: RxCBService(service: service)), error))
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
            didSubscribeToCharacteristicSubject.onNext(
                (Central(central: RxCBCentral(central: central)),
                Characteristic(characteristic: RxCBCharacteristic(characteristic: characteristic), service: <#T##Service#>))
            )
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
            didUnsubscribeFromCharacteristicSubject.onNext(
                (Central(central: RxCBCentral(central: central)),
                Characteristic(characteristic: RxCBCharacteristic(characteristic: characteristic), service: <#T##Service#>))
            )
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
            didRecieveReadRequestSubject.onNext(Request(request: RxCBRequest(request: request)))
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
            didRecieveWriteRequestsSubject.onNext(requests.map(RxCBRequest.init).map(Request.init))
        }
        
        @objc func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
            readyToUpdateSubscribersSubject.onNext()
        }
    }
    
}