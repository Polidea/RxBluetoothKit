//
//  Characteristic.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import RxSwift
import CoreBluetooth

public class Characteristic {
    let characteristic: RxCharacteristicType
    public let service: Service
    public var value: NSData? {
        return characteristic.value
    }
    public var uuid: CBUUID {
        return characteristic.uuid
    }
    public var isNotifying: Bool {
        return characteristic.isNotifying
    }
    public var properties: CBCharacteristicProperties {
        return characteristic.properties
    }
    public var descriptors: [Descriptor]? {
        return characteristic.descriptors?.map { Descriptor(descriptor: $0, characteristic: self) }
    }
    
    init(characteristic: RxCharacteristicType, service: Service) {
        self.characteristic = characteristic
        self.service = service
    }
    public func monitorWrite() -> Observable<Characteristic>{
        return Observable.never()
    }
    public func writeValue(data: NSData,type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return Observable.never()
    }
    func setNotifyValue(enabled: Bool) -> Observable<Characteristic>{
        return Observable.never()
    }
    
    //MARK: Reading characteristic values
    func monitorValueUpdate() -> Observable<Characteristic> {
        return Observable.never()
    }
    func readValue() -> Observable<Characteristic>{
        return Observable.never()
    }
}
extension Characteristic: Equatable {}
public func ==(lhs: Characteristic, rhs: Characteristic) -> Bool {
    return lhs.characteristic == rhs.characteristic
}