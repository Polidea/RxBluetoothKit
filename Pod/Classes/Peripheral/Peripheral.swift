//
//  Peripheral.swift
//  Pods
//
//  Created by Przemysław Lenart on 24/02/16.
//
//

import Foundation
import RxSwift
import CoreBluetooth


public class Peripheral {


    /// Implementation of peripheral
    let peripheral: RxPeripheralType


    var isConnected: Bool {
        return peripheral.state == .Connected
    }

    // Current state of peripheral
    public var state: CBPeripheralState {
        return peripheral.state
    }

    /// Name of a peripheral
    public var name: String? {
        return peripheral.name
    }

    // Peripheral identifier
    public var identifier: NSUUID {
        return peripheral.identifier
    }

    // Currently hold services
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
     Triggers services discovery.
     - Parameter identifiers: Identifiers of wanted services
     - Returns: Array of discovered services
     */
    public func discoverServices(identifiers: [CBUUID]?) -> Observable<[Service]> {
        let observable = peripheral.rx_didDiscoverServices
        .flatMap({
            (services, error) -> Observable<[Service]> in
            if let discoveredServices = services {
                let mapped = discoveredServices
                .filter { self.shouldBeIdentifierIncluded($0.uuid, forIdentifiers: identifiers) }
                .map { Service(peripheral: self, service: $0) as Service }
                return Observable.just(mapped)
            }
            return Observable.error(BluetoothError.ServicesDiscoveryFailed(self, error))
        })
        return Observable.deferred {
            self.peripheral.discoverServices(identifiers)
            return self.ensureValidPeripheralState(observable)
        }
    }



    /**
     Triggers included services discovery.
     - Parameter identifiers: Array of  services identifiers
     - Parameter service: The service whose included services you want to discover.
     - Returns: Returns array of included discovered services.
     */
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, forService service: Service) -> Observable<[Service]> {
        let observable = peripheral.rx_didDiscoverIncludedServicesForService
        .flatMap{ (service, error) ->Observable<[Service]> in
            if let includedServices = service.includedServices where error == nil {
                let services = includedServices
                .filter { self.shouldBeIdentifierIncluded($0.uuid, forIdentifiers: includedServiceUUIDs) }
                .map { Service(peripheral: self, service: $0) }
                return Observable.just(services)
            }
            return Observable.error(BluetoothError.IncludedServicesDiscoveryFailed(self, error))
        }
        return Observable.deferred {
            self.peripheral.discoverIncludedServices(includedServiceUUIDs, forService: service.service)
            return self.ensureValidPeripheralState(observable)
        }
    }

    //MARK: Characteristics

    /**
     Triggers characteristics discovery for specified service.
    - Parameter identifiers: Identifiers of wanted characteristics
    - Returns: Stream of characteristics
    */
    public func discoverCharacteristics(identifiers: [CBUUID]?, service: Service) -> Observable<[Characteristic]> {
        let observable = peripheral.rx_didDiscoverCharacteristicsForService
        .flatMap { (cbService, error) -> Observable<[Characteristic]> in
            if let characteristics = cbService.characteristics where error == nil {
                let filtered = characteristics
                .filter { self.shouldBeIdentifierIncluded($0.uuid, forIdentifiers: identifiers) }
                .map { Characteristic(characteristic: $0, service: service) }
                return Observable.just(filtered)
            }
            return Observable.error(BluetoothError.CharacteristicsDiscoveryFailed(service, error))
        }
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
     - Parameter characteristic: Characteristic to connect
     - Returns: Stream of characteristic, for which value write was detected
     */
    public func writeValue(data: NSData, forCharacteristic characteristic: Characteristic, type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return Observable.deferred {
            //TODO: Check state before call?
            self.peripheral.writeValue(data, forCharacteristic: characteristic.characteristic, type: type)
            return self.ensureValidPeripheralState(self.monitorWriteForCharacteristic(characteristic))
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
            return self.monitorValueUpdateForCharacteristic(characteristic)
        }
    }

    //MARK: Descriptors

    /**
      Triggers descriptors discovery for characteristics
    - Parameter characteristic: Characteristic for which descriptors will be discovered
    - Returns: Array of descriptors
    */
    public func discoverDescriptorsForCharacteristic(characteristic: Characteristic) -> Observable<[Descriptor]> {
        return Observable.unimplemented()
    }


    /**
     It connects to events of writes for  descriptor.
    - Parameter characteristic: Descriptor to connect
    - Returns: Stream of characteristic, for which value write was detected
    */
    public func monitorWriteForDescriptor(descriptor: Descriptor) -> Observable<Characteristic> {
        return Observable.unimplemented()
    }

    /**
      Writes given data to descriptor
     - Parameter data: Characteristic to connect
     - Parameter descriptor: descriptor to write value to
     - Returns: Stream of descriptor
     */
    public func writeValue(data: NSData, forDescriptor descriptor: Descriptor) -> Observable<Descriptor> {
        return Observable.unimplemented()
    }

    /**
     It connects to events of value updates for descriptor.
     - Parameter characteristic: Descriptor to connect
     - Returns: Stream of characteristic, for which value change was detected
     */
    public func monitorValueUpdateForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
        return Observable.unimplemented()
    }

    /**
     Reads data from given descriptor.
     - Parameter characteristic: Descriptor to read value from
     - Returns: Stream of characteristic, for which value write was detected
     */
    public func readValueForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
        return Observable.unimplemented()
    }

    /**
     detectErrorsObservable: Function that merges given observable with error streams. Helps propagate errors with connection, while calling another functions
     - Parameter observable: observation to be transformed
     - Returns: Observable<T> :transformed input  observation
     */
    func ensureValidPeripheralState<T>(observable: Observable<T>) -> Observable<T> {
        return Observable.deferred {
            guard self.isConnected else {
                return Observable.error(BluetoothError.PeripheralDisconnected(self, nil))
            }
            return Observable.of(self.manager.ensurePeripheralIsConnected(self),
                    self.manager.ensureState(.PoweredOn, observable: observable)).merge()
        }
    }

    /**
     Changes state of characteristic notify mode
    - Parameter enabled: state to set
    - Parameter characteristic: Characteristic to change state
    - Returns: Stream of characteristic, for which value was updated
    */
    public func setNotifyValue(enabled: Bool, forCharacteristic characteristic: Characteristic) -> Observable<Characteristic> {
        let observable = peripheral.rx_didUpdateNotificationStateForCharacteristic
        .filter { $0.0 == characteristic.characteristic
        }
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
     Triggers read RSSI from peripheral
     - Returns: Peripheral which value is up-to date and current RSSI.
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
     Connects to name update events
     - Returns: Peripheral which name was updated, along with updated name.
     */
    public func monitorUpdateName() -> Observable<(Peripheral, String?)> {
        return peripheral.rx_didUpdateName
        .map { return (self, $0) }
    }

    /**
    Connects to services modification events
    - Returns: stream of arrays services that have been modificated
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

public func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
}
