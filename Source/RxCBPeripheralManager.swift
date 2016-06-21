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
    
    init(queue: dispatch_queue_t, options: [String : AnyObject]? = nil) {
        peripheralManager = CBPeripheralManager(delegate: internalDelegate, queue: queue, options: options)
    }
}

extension RxCBPeripheralManager {
    
    var rx_didUpdateState: Observable<CBPeripheralManagerState> {
        return internalDelegate.didUpdateStateSubject
    }
    
    var rx_willRestoreState: Observable<[String: AnyObject]> {
        return internalDelegate.willRestoreStateSubject
    }
    
    var rx_didStartAdvertising: Observable<NSError?> {
        return internalDelegate.didStartAdvertisingSubject
    }
    
    var rx_didAddService: Observable<(MutableService, NSError?)> {
        return internalDelegate.didAddServiceSubject
    }
    
    var rx_didSubscribeToCharacteristic: Observable<(Central, MutableCharacteristic)> {
        return internalDelegate.didSubscribeToCharacteristicSubject
    }
    
    var rx_didUnsubscrubeFromCharacteristic: Observable<(Central, MutableCharacteristic)> {
        return internalDelegate.didUnsubscribeFromCharacteristicSubject
    }
    
    var rx_didRecieveReadRequst: Observable<Request> {
        return internalDelegate.didRecieveReadRequestSubject
    }
    
    var rx_didRecieveWriteRequests: Observable<[Request]> {
        return internalDelegate.didRecieveWriteRequestsSubject
    }
    
    var rx_readyToUpdateSubscribers: Observable<Void> {
        return internalDelegate.readyToUpdateSubscribersSubject
    }
    
    /// Current continous state of manager state
    var rx_state: Observable<CBPeripheralManagerState> {
        return peripheralManager
            .rx_observeWeakly(CBPeripheralManagerState.self, "state")
            .flatMap {
                state -> Observable<CBPeripheralManagerState> in
                guard let state = state else {
                    return Observable.error(BluetoothError.BluetoothInUnknownState)
                }
                return Observable.just(state)
            }
            .replay(1)
    }
    
    // should this be renamed to rx_advertising?
    var rx_isAdvertising: Observable<Bool> {
        return peripheralManager
            .rx_observeWeakly(Bool.self, "isAdvertising")
            .flatMap {
                advertising -> Observable<Bool> in
                guard let advertising = advertising else {
                    return .error(BluetoothError.BluetoothInUnknownState) // is this the right error to throw? Should a new one be created? Should we instead force unwrap this?? The only case where advertising is nil is when the weak observer is observing on a peripheralManager that is nil - will that ever even happen?
                }
                return .just(advertising)
            }
            .replay(1)
    }
}

extension RxCBPeripheralManager {
    
    func startAdvertising(advertismentData: AdvertisementData) {
        return peripheralManager.startAdvertising(advertismentData.advertisementData)
    }
    
    func stopAdvertising() {
        return peripheralManager.stopAdvertising()
    }
    
    func setDesiredConnectionLatency(latency: CBPeripheralManagerConnectionLatency, forCentral central: RxCentralType) {
        return peripheralManager.setDesiredConnectionLatency(latency, forCentral: (central as! RxCBCentral).central)
    }
    
    func addService(service: RxServiceType) {
        let srvc = (service as! RxCBService).service
        let mutableService = CBMutableService(type: srvc.UUID, primary: srvc.isPrimary)
        
        return peripheralManager.addService(mutableService)
    }
    
    func removeService(service: RxServiceType) {
        let srvc = (service as! RxCBService).service
        let mutableService = CBMutableService(type: srvc.UUID, primary: srvc.isPrimary)
        
        return peripheralManager.removeService(mutableService)
    }
    
    func removeAllServices() {
        return peripheralManager.removeAllServices()
    }
    
    func respondToRequest(request: RxRequestType, withResult result: CBATTError) {
        return peripheralManager.respondToRequest((request as! RxCBRequest).request, withResult: result)
    }
    
    func updateValue(value: NSData, forCharacteristic characteristic: RxMutableCharacteristicType, onSubscribedCentrals centrals: [RxCentralType]?) -> Bool {
        return peripheralManager.updateValue(value,
                                             forCharacteristic: CBMutableCharacteristic(type: characteristic.UUID, properties: characteristic.properties, value: characteristic.value, permissions: characteristic.permissions),
                                             onSubscribedCentrals: centrals?.map { $0.central })
    }
}

extension RxCBPeripheralManager {
    
    private class InternalDelegate: NSObject, CBPeripheralManagerDelegate {
        let didUpdateStateSubject = PublishSubject<CBPeripheralManagerState>()
        let willRestoreStateSubject = PublishSubject<[String: AnyObject]>()
        let didStartAdvertisingSubject = PublishSubject<NSError?>()
        let didAddServiceSubject = PublishSubject<(MutableService, NSError?)>()
        let didSubscribeToCharacteristicSubject = PublishSubject<(Central, MutableCharacteristic)>()
        let didUnsubscribeFromCharacteristicSubject = PublishSubject<(Central, MutableCharacteristic)>()
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
            guard let mutableService = service as? CBMutableService
                else { assertionFailure(); return }
            
            didAddServiceSubject.onNext((MutableService(service: mutableService), error))
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
            let central = Central(central: RxCBCentral(central: central))
            let cbCharacteristic = RxCBCharacteristic(characteristic: characteristic)
            let cbService = RxCBService(service: characteristic.service)
            let cbPeripheral = RxCBPeripheral(peripheral: characteristic.service.peripheral)
//            let peripheral = Peripheral(manager: <#T##BluetoothManager#>, peripheral: cbPeripheral)
//            
//            let service = Service(peripheral: peripheral, service: cbService)
//            let characteristic = Characteristic(characteristic: RxCBCharacteristic(characteristic: characteristic), service: service)
//            
//            didSubscribeToCharacteristicSubject.onNext((central, characteristic))
        }
        
        @objc func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
//            didUnsubscribeFromCharacteristicSubject.onNext(
//                (Central(central: RxCBCentral(central: central)),
//                Characteristic(characteristic: RxCBCharacteristic(characteristic: characteristic), service: <#T##Service#>))
//            )
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