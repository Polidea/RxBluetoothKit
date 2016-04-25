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
import CoreBluetooth
import RxSwift

// swiftlint:disable line_length

extension Peripheral {

    /**
     Function used to receive service with given identifier. It's taken from cache if it's available,
     or directly by `discoverServices` call
     - Parameter identifier: Unique identifier of Service
     - Returns: Observation which emits `Next` event, when specified service has been found.
     Immediately after that `.Complete` is emitted.
     */
    public func serviceWithIdentifier(identifier: ServiceIdentifier) -> Observable<Service> {
        return Observable.deferred {
            if let services = self.services,
                let service = services.findElement({ $0.UUID == identifier.UUID  }) {
                return Observable.just(service)
            } else {
                return Observable.from(self.discoverServices([identifier.UUID]))
            }
        }
    }

    /**
     Function used to receive characteristic with given identifier. If it's available it's taken from cache.
     Otherwise - directly by `discoverCharacteristics` call
     - Parameter identifier: Unique identifier of Characteristic, that has information
     about service which characteristic belongs to.
     - Returns: Observation which emits `Next` event, when specified characteristic has been found.
     Immediately after that `.Complete` is emitted.
     */
    public func characteristicWithIdentifier(identifier: CharacteristicIdentifier) -> Observable<Characteristic> {
        return Observable.deferred {
            return self.serviceWithIdentifier(identifier.service)
                .flatMap { service -> Observable<Characteristic> in
                    if let characteristics = service.characteristics, let characteristic = characteristics.findElement({
                        $0.UUID == identifier.UUID
                    }) {
                        return Observable.just(characteristic)
                    } else {
                        return Observable.from(service.discoverCharacteristics([identifier.UUID]))
                    }
            }
        }
    }

    /**
     Function used to receive descriptor with given identifier. If it's available it's taken from cache.
     Otherwise - directly by `discoverDescriptor` call
     - Parameter identifier: Unique identifier of Descriptor, that has information
     about characteristic which descriptor belongs to.
     - Returns: Observation which emits `Next` event, when specified descriptor has been found.
     Immediately after that `.Complete` is emitted.
     */
    public func descriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return Observable.deferred {
            return self.characteristicWithIdentifier(identifier.characteristic)
                .flatMap { characteristic -> Observable<Descriptor> in
                    if let descriptors = characteristic.descriptors,
                        let descriptor = descriptors.findElement({ $0.UUID == identifier.UUID }) {
                        return Observable.just(descriptor)
                    } else {
                        return Observable.from(characteristic.discoverDescriptors())
                            .filter { $0.UUID == identifier.UUID }
                            .take(1)
                    }
            }
        }
    }

    /**
     Function that allow to monitor writes that happened for characteristic.
     - Parameter identifier: Identifier of characteristic of which value writes should be monitored.
     - Returns: Observable that emits `Next` with `Characteristic` instance every time when write has happened.
     It's **infinite** stream, so `.Complete` is never called.
     */
    public func monitorWriteForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.monitorWriteForCharacteristic($0)
        }
    }

    /**
     Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
     Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/swift/enum/c:@E@CBCharacteristicWriteType), so be sure to check this out before usage of the method.
     - parameter data: Data that'll be written  written to `Characteristic` instance
     - parameter forCharacteristicWithIdentifier: unique identifier of service, which also holds information about service characteristic belongs to.
     `Descriptor` instance to write value to.
     - parameter type: Type of write operation. Possible values: `.WithResponse`, `.WithoutResponse`
     - returns: Observable that emition depends on `CBCharacteristicWriteType` passed to the function call.
     Behavior is following:

     - `WithResponse` -  Observable emits `Next` with `Characteristic` instance write was confirmed without any errors.
     Immediately after that `Complete` is called. If any problem has happened, errors are emitted.
     - `WithoutResponse` - Observable emits `Next` with `Characteristic` instance once write was called.
     Immediately after that `.Complete` is called. Result of this call is not checked, so as a user you are not sure
     if everything completed successfully. Errors are not emitted
     */
    public func writeValue(data: NSData, forCharacteristicWithIdentifier identifier: CharacteristicIdentifier,
                    type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.writeValue(data, forCharacteristic: $0, type: type)
        }
    }

    /**
     Function that allow to monitor value updates for `Characteristic` instance.
     - Parameter identifier: unique identifier of service, which also holds information about service that characteristic belongs to.
     - Returns: Observable that emits `Next` with `Characteristic` instance every time when value has changed.
     It's **infinite** stream, so `.Complete` is never called.
     */
    public func monitorValueUpdateForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.monitorValueUpdateForCharacteristic($0)
        }
    }

    /**
     Function that triggers read of current value of the `Characteristic` instance.
     Read is called after subscription to `Observable` is made.
     - Parameter identifier: unique identifier of service, which also holds information about service that characteristic belongs to.
     - Returns: Observable which emits `Next` with given characteristic when value is ready to read. Immediately after that
     `.Complete` is emitted.
     */
    public func readValueForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier) -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.readValueForCharacteristic($0)
        }
    }

    /**
     Function that triggers set of notification state of the `Characteristic`.
     This change is called after subscribtion to `Observable` is made.
     - warning: This method is not responsible for emitting values every time that `Characteristic` value is changed.
     For this, refer to other method: `monitorValueUpdateForCharacteristic(_)`. These two are often called together.
     - parameter enabled: New value of notifications state. Specify `true` if you're interested in getting values
     - parameter identifier: unique identifier of service, which also holds information about service that characteristic belongs to.
     - returns: Observable which emits `Next` with Characteristic that state was changed. Immediately after `.Complete`
     is emitted
     */
    public func setNotifyValue(enabled: Bool, forCharacteristicWithIdentifier identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
            return characteristicWithIdentifier(identifier)
                .flatMap {
                    return self.setNotifyValue(enabled, forCharacteristic: $0)
            }
    }

    /**
     Function that triggers set of notification state of the `Characteristic`, and monitor for any incoming updates.
     Notification is set after subscribtion to `Observable` is made.
   - parameter identifier: unique identifier of service, which also holds information about service that characteristic belongs to.
     - returns: Observable which emits `Next`, when characteristic value is updated.
     This is **infinite** stream of values.
     */
    public func setNotificationAndMonitorUpdatesForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
            return characteristicWithIdentifier(identifier)
                .flatMap {
                    return self.setNotificationAndMonitorUpdatesForCharacteristic($0)
            }
    }

    /**
     Function that triggers descriptors discovery for characteristic
     - Parameter characteristic: `Characteristic` instance for which descriptors should be discovered.
      - parameter identifier: unique identifier of descriptor, which also holds information about characteristic that descriptor belongs to.
     - Returns: Observable that emits `Next` with array of `Descriptor` instances, once they're discovered.
     Immediately after that `.Complete` is emitted.
     */
    public func discoverDescriptorsForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier) ->
        Observable<[Descriptor]> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.discoverDescriptorsForCharacteristic($0)
        }
    }

    /**
     Function that allow to monitor writes that happened for descriptor.
      - parameter identifier: unique identifier of descriptor, which also holds information about characteristic that descriptor belongs to.
     - Returns: Observable that emits `Next` with `Descriptor` instance every time when write has happened.
     It's **infinite** stream, so `.Complete` is never called.
     */
    public func monitorWriteForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.monitorWriteForDescriptor($0)
        }
    }

    /**
     Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
     - Parameter data: `NSData` that'll be written to `Descriptor` instance
      - parameter identifier: unique identifier of descriptor, which also holds information about characteristic that descriptor belongs to.
     - Returns: Observable that emits `Next` with `Descriptor` instance, once value is written successfully.
     Immediately after that `.Complete` is emitted.
     */
    public func writeValue(data: NSData, forDescriptorWithIdentifier identifier: DescriptorIdentifier)
        -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.writeValue(data, forDescriptor: $0)
        }
    }

    /**
     Function that allow to monitor value updates for `Descriptor` instance.
      - parameter identifier: unique identifier of descriptor, which also holds information about characteristic that descriptor belongs to.
     - Returns: Observable that emits `Next` with `Descriptor` instance every time when value has changed.
     It's **infinite** stream, so `.Complete` is never called.
     */
    public func monitorValueUpdateForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.monitorValueUpdateForDescriptor($0)
        }
    }

    /**
     Function that triggers read of current value of the `Descriptor` instance.
     Read is called after subscription to `Observable` is made.
     - Parameter descriptor: `Descriptor` to read value from
     - Returns: Observable which emits `Next` with given descriptor when value is ready to read. Immediately after that
     `.Complete` is emitted.
     */
    public func readValueForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.readValueForDescriptor($0)
        }
    }
}
