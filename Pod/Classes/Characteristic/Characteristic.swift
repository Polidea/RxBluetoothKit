//
//  Characteristic.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import RxSwift
import CoreBluetooth

/**
 Class which describe characteristic of a bluetooth low energy service.
 */
public class Characteristic {
    let characteristic: RxCharacteristicType

    /// Service which contains this characteristic
    public let service: Service

    /// Characteristic value or nil if not present
    public var value: NSData? {
        return characteristic.value
    }

    /// Characteristic UUID
    public var uuid: CBUUID {
        return characteristic.uuid
    }

    /// Flag which is set to true if characteristic is notifying
    public var isNotifying: Bool {
        return characteristic.isNotifying
    }

    /// Characteristic properties
    public var properties: CBCharacteristicProperties {
        return characteristic.properties
    }

    /// Characteristic descriptors
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

    /**
     Function which monitors writes to this characteristic after subscription to
     returned observable.

     - returns: Observable which emits this characteristic if write operation was
                performed on it.
     */
    public func monitorWrite() -> Observable<Characteristic> {
        return service.peripheral.monitorWriteForCharacteristic(self)
    }

    /**
     Function which writes value to this characteristic.

     - parameter data: Data to be written
     - parameter type: Type of write operation.
     - returns: Observable which emits this characteristic if write succeeded.
     */
    public func writeValue(data: NSData, type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return service.peripheral.writeValue(data, forCharacteristic: self, type: type)
    }

    /**
     Set if value changes of this characteristic should be notified to Central Manager. Changes
     can be observed by use of monitorValueUpdate() function.

     - parameter enabled: True if notifications should be turned on
     - returns: Observable which emits this characteristic if notify value changed successfully.
     */
    public func setNotifyValue(enabled: Bool) -> Observable<Characteristic> {
        return service.peripheral.setNotifyValue(enabled, forCharacteristic: self)
    }

    // MARK: Reading characteristic values

    /**
     Monitor value changes of a characteristic. After subscription to returned observable all
     characteristic value changes are emitted by it. Changes done by peripheral itself are not
     monitored until notification for this characteristic are not enabled.

     - returns: Observable which emits this characteristic when its value changed.
     */
    public func monitorValueUpdate() -> Observable<Characteristic> {
        return service.peripheral.monitorValueUpdateForCharacteristic(self)
    }

    /**
     This funciton request read from a characteristic. When this characteristic is emitted by returned
     observable it is ready to read new value from it.

     - returns: Observable which emits this characteristic when data is ready to be read.
     */
    public func readValue() -> Observable<Characteristic> {
        return service.peripheral.readValueForCharacteristic(self)
    }
}

extension Characteristic: Equatable {}

/**
 Compare two characteristics. Characteristics are the same when their UUIDs are the same.

 - parameter lhs: First characteristic to compare
 - parameter rhs: Second characteristic to compare
 - returns: True if both characteristics are the same.
 */
public func == (lhs: Characteristic, rhs: Characteristic) -> Bool {
    return lhs.characteristic == rhs.characteristic
}
