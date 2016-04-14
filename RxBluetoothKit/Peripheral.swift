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
 Bluetooth manager's peripheral
*/
public class Peripheral {

    /// Implementation of peripheral
    let peripheral: RxPeripheralType


    var isConnected: Bool {
        return peripheral.state == .Connected
    }

    /// Current state of peripheral
    public var state: CBPeripheralState {
        return peripheral.state
    }

    /// Name of a peripheral
    public var name: String? {
        return peripheral.name
    }

    /// Peripheral identifier
    public var identifier: NSUUID {
        return peripheral.identifier
    }

    /// Currently hold services
    public var services: [Service]? {
        return peripheral.services?.map {
            Service(peripheral: self, service: $0)
        }
    }

    let manager: BluetoothManager

    init(manager: BluetoothManager, peripheral: RxPeripheralType) {
        self.manager = manager
        self.peripheral = peripheral
    }

    /**
     Establishes connection with BLE Peripheral
     - Parameter options: Connection options
     - Returns: Observation which emits next event after connection is established
     */
    public func connect(options: [String:AnyObject]? = nil) -> Observable<Peripheral> {
        return manager.connectToPeripheral(self, options: options)
    }

    /**
     Connects to BLE Peripheral
     - Returns: Observation which emits next event after peripheral is disconnected
     */
    public func cancelConnection() -> Observable<Peripheral> {
        return manager.cancelConnectionToPeripheral(self)
    }

    /**
     Triggers services discovery. Completes right after first discovery.
     - Parameter identifiers: Identifiers of wanted services
     - Returns: Array of discovered services
     */
    public func discoverServices(identifiers: [CBUUID]?) -> Observable<[Service]> {
        let observable = peripheral.rx_didDiscoverServices
        .flatMap({
            (services, error) -> Observable<[Service]> in
            if let discoveredServices = services {
                let mapped = discoveredServices.map { Service(peripheral: self, service: $0) }
                guard let identifiers = identifiers else { return Observable.just(mapped) }
                let uuids = discoveredServices.map { $0.uuid }
                if Set(uuids) == Set(identifiers) {
                    return Observable.just(mapped)
                }
                return Observable.empty()
            }
            return Observable.error(BluetoothError.ServicesDiscoveryFailed(self, error))
        })
        .take(1)

        return Observable.deferred {
            self.peripheral.discoverServices(identifiers)
            return self.ensureValidPeripheralState(observable)
        }
    }

    /**
     Triggers included services discovery. Completes right after first discovery.

     - parameter includedServiceUUIDs: Array of  services identifiers
     - parameter forService: The service whose included services you want to discover.
     - returns: An array of included discovered services.
     */
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?,
                                         forService service: Service) -> Observable<[Service]> {
        let observable = peripheral.rx_didDiscoverIncludedServicesForService
            .filter { $0.0 == service.service }
            .flatMap {(service, error) -> Observable<[Service]> in
                guard let includedServices = service.includedServices where error == nil else {
                    return Observable.error(BluetoothError.IncludedServicesDiscoveryFailed(self, error))
                }
                let mapped = includedServices.map { Service(peripheral: self, service: $0) }
                guard includedServiceUUIDs != nil else { return Observable.just(mapped) }
                return Observable.just(mapped
                .filter { self.shouldBeIdentifierIncluded($0.uuid, forIdentifiers: includedServiceUUIDs) })
            }
            .take(1)

        return Observable.deferred {
            self.peripheral.discoverIncludedServices(includedServiceUUIDs, forService: service.service)
            return self.ensureValidPeripheralState(observable)
        }
    }

    //MARK: Characteristics

    /**
     Triggers characteristics discovery for specified service.

    - parameter identifiers: Identifiers of wanted characteristics
    - parameter service: Service which includes characteristics to be discovered
    - returns: Stream of characteristics
    */
    public func discoverCharacteristics(identifiers: [CBUUID]?, service: Service) -> Observable<[Characteristic]> {
        let observable = peripheral.rx_didDiscoverCharacteristicsForService
        .filter { $0.0 == service.service }
        .flatMap { (cbService, error) -> Observable<[Characteristic]> in
            guard let characteristics = cbService.characteristics where error == nil else {
                return Observable.error(BluetoothError.CharacteristicsDiscoveryFailed(service, error))
            }
            let mapped = characteristics.map { Characteristic(characteristic: $0, service: service) }
            guard identifiers != nil else { return Observable.just(mapped) }
            return Observable.just(mapped
                .filter { self.shouldBeIdentifierIncluded($0.uuid, forIdentifiers: identifiers) })
        }
        .take(1)

        return Observable.deferred {
            self.peripheral.discoverCharacteristics(identifiers, forService: service.service)
            return self.ensureValidPeripheralState(observable)
        }
    }

    /**
     It connects to events of writes for characteristics.
     - Parameter characteristic: Characteristic to connect
     - Returns: Stream of characteristic, for which value write was detected
     */
    public func monitorWriteForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
        return peripheral.rx_didWriteValueForCharacteristic
        .filter { return $0.0 == characteristic.characteristic
        }
        .flatMap { (rxCharacteristic, error) -> Observable<Characteristic> in
            if let error = error {
                return Observable.error(BluetoothError.CharacteristicWriteFailed(characteristic, error))
            }
            return Observable.just(characteristic)
        }
    }

    /**
     Writes given data to characteristic

     - parameter data: Data to be written to characteristic
     - parameter forCharacteristic: Characteristic into which data will be written
     - parameter type: Type of write operation
     - returns: Observable which emit characteristic to which value was written
     */
    public func writeValue(data: NSData,
                           forCharacteristic characteristic: Characteristic,
                           type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return Observable.deferred {
            //TODO: Check state before call?
            self.peripheral.writeValue(data, forCharacteristic: characteristic.characteristic, type: type)
            switch type {
            case .WithoutResponse:
                return self.ensureValidPeripheralState(Observable.just(characteristic))
            case .WithResponse:
                return self.ensureValidPeripheralState(self.monitorWriteForCharacteristic(characteristic).take(1))
            }
        }
    }

    /**
     It connects to events of value updates for characteristics.
     - Parameter characteristic: Characteristic to connect
     - Returns: Stream of characteristic, for which value change was detected
     */
    public func monitorValueUpdateForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
        let observable = peripheral.rx_didUpdateValueForCharacteristic
        .filter { $0.0 == characteristic.characteristic }
        .flatMap {(rxCharacteristic, error) -> Observable<Characteristic> in
            if let error = error {
                return Observable.error(BluetoothError.CharacteristicReadFailed(characteristic, error))
            }
            return Observable.just(characteristic)
        }
        return self.ensureValidPeripheralState(observable)
    }


    /**
     Reads data from characteristic.
     - Parameter characteristic: Characteristic to read value from
     - Returns: Stream of characteristic, for which value write was detected
     */
    public func readValueForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
        return Observable.deferred {
            // TODO: check state before call?
            self.peripheral.readValueForCharacteristic(characteristic.characteristic)
            return self.monitorValueUpdateForCharacteristic(characteristic).take(1)
        }
    }

    //MARK: Descriptors
    /**
      Triggers descriptors discovery for characteristics
    - Parameter characteristic: Characteristic for which descriptors will be discovered
    - Returns: Array of descriptors
    */
    public func discoverDescriptorsForCharacteristic(characteristic: Characteristic) -> Observable<[Descriptor]> {
        let observable = peripheral.rx_didDiscoverDescriptorsForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .flatMap { (cbCharacteristic, error) -> Observable<[Descriptor]> in
                if let descriptors = cbCharacteristic.descriptors where error == nil {
                        return Observable.just(descriptors.map {
                            Descriptor(descriptor: $0, characteristic: characteristic)})
                    }
                    return Observable.error(BluetoothError.DescriptorsDiscoveryFailed(characteristic, error))
                }

            return Observable.deferred {
                self.peripheral.discoverDescriptorsForCharacteristic(characteristic.characteristic)
                return self.ensureValidPeripheralState(observable)
            }
    }

    /**
     It connects to events of writes for  descriptor.
    - Parameter descriptor: Descriptor to connect
    - Returns: Stream of descriptors for which value write was detected
    */
    public func monitorWriteForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
        return peripheral.rx_didWriteValueForDescriptor
            .filter { $0.0 == descriptor.descriptor }
            .flatMap { (rxDescriptor, error) -> Observable<Descriptor> in
                if let error = error {
                    return Observable.error(BluetoothError.DescriptorWriteFailed(descriptor, error))
                }
                return Observable.just(descriptor)
            }
    }

    /**
      Writes given data to descriptor
     - Parameter data: Characteristic to connect
     - Parameter descriptor: descriptor to write value to
     - Returns: Stream of descriptor
     */
    public func writeValue(data: NSData, forDescriptor descriptor: Descriptor) -> Observable<Descriptor> {
        return Observable.deferred {
            //TODO: Check state before call?
            self.peripheral.writeValue(data, forDescriptor: descriptor.descriptor)
            return self.ensureValidPeripheralState(self.monitorWriteForDescriptor(descriptor).take(1))
        }
    }

    /**
     It connects to events of value updates for descriptor.
     - Parameter descriptor: Descriptor to connect
     - Returns: Stream of characteristic, for which value change was detected
     */
    public func monitorValueUpdateForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
        let observable = peripheral.rx_didUpdateValueForDescriptor
            .filter { $0.0 == descriptor.descriptor }
            .flatMap { (rxDescriptor, error) -> Observable<Descriptor> in
                if let error = error {
                    return Observable.error(BluetoothError.DescriptorReadFailed(descriptor, error))
                }
                return Observable.just(descriptor)
        }
        return self.ensureValidPeripheralState(observable)
    }

    /**
     Reads data from given descriptor.
     - Parameter descriptor: Descriptor to read value from
     - Returns: Observable which emits given descriptor when value is read from it
     */
    public func readValueForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
        return Observable.deferred {
            self.peripheral.readValueForDescriptor(descriptor.descriptor)
            return self.monitorValueUpdateForDescriptor(descriptor).take(1)
        }
    }

    /**
     Function that merges given observable with error streams of invalid Central Manager states.

     - Parameter observable: observation to be transformed
     - Returns: Source observable which listens on state chnage errors as well
     */
    func ensureValidPeripheralState<T>(observable: Observable<T>) -> Observable<T> {
        return Observable.deferred {
            guard self.isConnected else {
                return Observable.error(BluetoothError.PeripheralDisconnected(self, nil))
            }
            return Observable.absorb(self.manager.ensurePeripheralIsConnected(self),
                                     self.manager.ensureState(.PoweredOn, observable: observable))
        }
    }

    /**
     Changes state of characteristic notify mode
    - Parameter enabled: state to set
    - Parameter forCharacteristic: Characteristic to change state
    - Returns: Observable which emits given characteristic when notification option has changed.
    */
    public func setNotifyValue(enabled: Bool,
                               forCharacteristic characteristic: Characteristic) -> Observable<Characteristic> {
        let observable = peripheral.rx_didUpdateNotificationStateForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .flatMap { (rxCharacteristic, error) -> Observable<Characteristic> in
                if let error = error {
                    return Observable.error(BluetoothError.CharacteristicNotifyChangeFailed(characteristic, error))
                }
                return Observable.just(characteristic)
            }
        return Observable.deferred {
            //TODO: Check state before call?
            self.peripheral.setNotifyValue(enabled, forCharacteristic: characteristic.characteristic)
            return self.ensureValidPeripheralState(observable).take(1)
        }
    }

    /**
     Read peripheral's RSSI
     returns: Observable which after subscribe execute operation to read peripheral's RSSI and emits given result
     */
    public func readRSSI() -> Observable<(Peripheral, Int)> {
        let observable = peripheral.rx_didReadRSSI
        .flatMap { (rssi, error) -> Observable<(Peripheral, Int)> in
            if let error = error {
                return Observable.error(BluetoothError.PeripheralRSSIReadFailed(self, error))
            }
            return Observable.just(self, rssi)
        }
        return Observable.deferred {
            self.peripheral.readRSSI()
            return self.ensureValidPeripheralState(observable)
        }
    }

    /**
     Monitor name changes of peripheral
     returns: Observable which after subscribe returns
     */
    public func monitorUpdateName() -> Observable<(Peripheral, String?)> {
        return peripheral.rx_didUpdateName
        .map { return (self, $0) }
    }

    /**
     Monitor peripheral's serices modification
     returns: Observable which after subcribe listens for serives modifications. As a result array
              of new services is returned.
    */
    public func monitorServicesModification() -> Observable<(Peripheral, [Service])> {
        let observable = peripheral.rx_didModifyServices
        .map { $0.map { Service(peripheral: self, service: $0) } }
        .map { (self, $0) }
        return ensureValidPeripheralState(observable)
    }

    private func shouldBeIdentifierIncluded(identifier: CBUUID, forIdentifiers identifiers: [CBUUID]?) -> Bool {
        if let identifiers = identifiers {
            return identifiers.contains(identifier)
        }
        return true
    }
}

extension Peripheral: Equatable {
}

/**
 Compare two peripherals which are the same when theirs identifiers are equal.

  - parameter lhs: First peripheral to compare
  - parameter rhs: Second peripheral to compare
  - returns: True if both peripherals are the same
 */
public func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
}
