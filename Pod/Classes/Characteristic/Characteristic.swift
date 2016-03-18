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
        return characteristic.descriptors?.map {
            Descriptor(descriptor: $0, characteristic: self)
        }
    }

    init(characteristic: RxCharacteristicType, service: Service) {
        self.characteristic = characteristic
        self.service = service
    }
    //MARK: Writing characteristic values
    public func monitorWrite() -> Observable<Characteristic> {
        return service.peripheral.monitorWriteForCharacteristic(self)
    }

    public func writeValue(data: NSData, type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return service.peripheral.writeValue(data, forCharacteristic: self, type: type)
    }

    public func setNotifyValue(enabled: Bool) -> Observable<Characteristic> {
        return service.peripheral.setNotifyValue(enabled, forCharacteristic: self)
    }

    //MARK: Reading characteristic values
    public func monitorValueUpdate() -> Observable<Characteristic> {
        return service.peripheral.monitorValueUpdateForCharacteristic(self)
    }

    public func readValue() -> Observable<Characteristic> {
        return service.peripheral.readValueForCharacteristic(self)
    }
}

extension Characteristic: Equatable {}

public func ==(lhs: Characteristic, rhs: Characteristic) -> Bool {
    return lhs.characteristic == rhs.characteristic
}