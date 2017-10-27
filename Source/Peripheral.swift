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
import RxSwift
import CoreBluetooth

// swiftlint:disable line_length

/// Peripheral is a class implementing ReactiveX API which wraps all Core Bluetooth functions
/// allowing to talk to peripheral like discovering characteristics, services and all of the read/write calls.
public class Peripheral {
    public let manager: BluetoothManager

    init(manager: BluetoothManager, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        peripheral.delegate = delegateWrapper
    }

    /// Implementation of peripheral
    public let peripheral: CBPeripheral
    private let delegateWrapper = CBPeripheralDelegateWrapper()

    ///  Continuous value indicating if peripheral is in connected state. This is continuous value, which first emits `.Next` with current state, and later whenever state change occurs
    public var rx_isConnected: Observable<Bool> {
        return .deferred {
            let disconnected = self.manager.monitorDisconnection(for: self).map { _ in false }
            let connected = self.manager.monitorConnection(for: self).map { _ in true }
            return Observable.of(disconnected, connected).merge().startWith(self.isConnected)
        }
    }

    /// Value indicating if peripheral is currently in connected state.
    public var isConnected: Bool {
        return peripheral.state == .connected
    }

    ///  Current state of `Peripheral` instance described by [CBPeripheralState](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/c/tdef/CBPeripheralState).
    ///  - returns: Current state of `Peripheral` as `CBPeripheralState`.
    public var state: CBPeripheralState {
        return peripheral.state
    }

    /// Current name of `Peripheral` instance. Analogous to   [name](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/c/tdef/name) of `CBPeripheral`.
    public var name: String? {
        return peripheral.name
    }

    /// Unique identifier of `Peripheral` instance. Assigned once peripheral is discovered by the system.

    public var identifier: UUID {
        return peripheral.value(forKey: "identifier") as! NSUUID as UUID
    }

    /// A list of services that have been discovered. Analogous to   [services](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/occ/instp/CBPeripheral/services) of `CBPeripheral`.
    public var services: [Service]? {
        return peripheral.services?.map {
            Service(peripheral: self, service: $0)
        }
    }

    /// YES if the remote device has space to send a write without response.  If this value is NO,
    /// the value will be set to YES after the current writes have been flushed, and
    /// `peripheralIsReadyToSendWriteWithoutResponse:` will be called.
    public var canSendWriteWithoutResponse: Bool {
        return peripheral.canSendWriteWithoutResponse
    }

    /// Establishes local connection to the peripheral.
    /// For more information look into `BluetoothManager.connectToPeripheral(_:options:)` because this method calls it directly.
    /// - Parameter peripheral: The `Peripheral` to which `BluetoothManager` is attempting to connect.
    /// - Parameter options: Dictionary to customise the behaviour of connection.
    /// - Returns: `Observable` which emits next event after connection is established
    public func connect(options: [String: AnyObject]? = nil) -> Single<Peripheral> {
        return manager.connect(self, options: options)
    }

    /// Cancels an active or pending local connection to a `Peripheral` after observable subscription. It is not guaranteed
    /// that physical connection will be closed immediately as well and all pending commands will not be executed.
    ///
    /// - returns: `Single` which emits next event when peripheral successfully cancelled connection.
    public func cancelConnection() -> Single<Peripheral> {
        return manager.cancelPeripheralConnection(self)
    }

    /// Triggers discover of specified services of peripheral. If the servicesUUIDs parameter is nil, all the available services of the
    /// peripheral are returned; setting the parameter to nil is considerably slower and is not recommended.
    /// If all of the specified services are already discovered - these are returned without doing any underlying Bluetooth operations.
    /// Next on returned `Observable` is emitted only when all of the requested services are discovered.
    ///
    /// - Parameter serviceUUIDs: An array of [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/) objects that you are interested in. Here, each [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/) object represents a UUID that identifies the type of service you want to discover.
    /// - Returns: `Single` that emits `Next` with array of `Service` instances, once they're discovered.
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) -> Single<[Service]> {
        if let identifiers = serviceUUIDs, !identifiers.isEmpty,
            let cachedServices = self.services,
            let filteredServices = filterUUIDItems(uuids: serviceUUIDs, items: cachedServices) {
            return ensureValidPeripheralState(for: .just(filteredServices)).asSingle()
        }
        let observable = delegateWrapper.rx_didDiscoverServices
            .flatMap { [weak self] (_, error) -> Observable<[Service]> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                guard let cachedServices = strongSelf.services, error == nil else {
                    throw BluetoothError.servicesDiscoveryFailed(strongSelf, error)
                }
                if let filteredServices = filterUUIDItems(uuids: serviceUUIDs, items: cachedServices) {
                    return .just(filteredServices)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in self?.peripheral.discoverServices(serviceUUIDs) }
        )
        .asSingle()
    }

    /// Function that triggers included services discovery for specified services. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// If all of the specified included services are already discovered - these are returned without doing any underlying Bluetooth
    /// operations.
    /// Next on returned `Observable` is emitted only when all of the requested included services are discovered.
    ///
    /// - Parameter includedServiceUUIDs: Identifiers of included services that should be discovered. If `nil` - all of the
    /// included services will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Parameter forService: Service of which included services should be discovered.
    /// - Returns: `Single` that emits `Next` with array of `Service` instances, once they're discovered.
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) -> Single<[Service]> {
        if let identifiers = includedServiceUUIDs, !identifiers.isEmpty,
            let services = service.includedServices,
            let filteredServices = filterUUIDItems(uuids: includedServiceUUIDs, items: services) {
            return ensureValidPeripheralState(for: .just(filteredServices)).asSingle()
        }
        let observable = delegateWrapper
            .rx_didDiscoverIncludedServicesForService
            .filter { $0.0 == service.service }
            .flatMap { [weak self] (service, error) -> Observable<[Service]> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                guard let includedRxServices = service.includedServices, error == nil else {
                    throw BluetoothError.includedServicesDiscoveryFailed(strongSelf, error)
                }
                let includedServices = includedRxServices.map { Service(peripheral: strongSelf, service: $0) }
                if let filteredServices = filterUUIDItems(uuids: includedServiceUUIDs, items: includedServices) {
                    return .just(filteredServices)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.discoverIncludedServices(includedServiceUUIDs, for: service.service)
            }
        )
        .asSingle()
    }

    // MARK: Characteristics

    /// Function that triggers characteristics discovery for specified Services and identifiers. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// If all of the specified characteristics are already discovered - these are returned without doing any underlying Bluetooth operations.
    /// Next on returned `Observable` is emitted only when all of the requested characteristics are discovered.
    ///
    /// - Parameter identifiers: Identifiers of characteristics that should be discovered. If `nil` - all of the
    /// characteristics will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Parameter service: Service of which characteristics should be discovered.
    /// - Returns: `Single` that emits `Next` with array of `Characteristic` instances, once they're discovered.
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) -> Single<[Characteristic]> {
        if let identifiers = characteristicUUIDs, !identifiers.isEmpty,
            let characteristics = service.characteristics,
            let filteredCharacteristics = filterUUIDItems(uuids: characteristicUUIDs, items: characteristics) {
            return ensureValidPeripheralState(for: .just(filteredCharacteristics)).asSingle()
        }
        let observable = delegateWrapper
            .rx_didDiscoverCharacteristicsForService
            .filter { $0.0 == service.service }
            .flatMap { (cbService, error) -> Observable<[Characteristic]> in
                guard let cbCharacteristics = cbService.characteristics, error == nil else {
                    throw BluetoothError.characteristicsDiscoveryFailed(service, error)
                }
                let characteristics = cbCharacteristics.map { Characteristic(characteristic: $0, service: service) }
                if let filteredCharacteristics = filterUUIDItems(uuids: characteristicUUIDs, items: characteristics) {
                    return .just(filteredCharacteristics)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.discoverCharacteristics(characteristicUUIDs, for: service.service)
            }
        ).asSingle()
    }

    /// Function that allow to monitor writes that happened for characteristic.
    /// - Parameter characteristic: Characteristic of which value writes should be monitored.
    /// - Returns: Observable that emits `Next` with `Characteristic` instance every time when write has happened.
    /// It's **infinite** stream, so `.Complete` is never called.
    public func monitorWrite(for characteristic: Characteristic) -> Observable<Characteristic> {
        let observable = delegateWrapper
            .rx_didWriteValueForCharacteristic
            .filter { return $0.0 == characteristic.characteristic }
            .map { (_, error) -> Characteristic in
                if let error = error {
                    throw BluetoothError.characteristicWriteFailed(characteristic, error)
                }
                return characteristic
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// @method    maximumWriteValueLengthForType:
    /// @discussion  The maximum amount of data, in bytes, that can be sent to a characteristic in a single write type.
    /// @see    writeValue:forCharacteristic:type:
    @available(OSX 10.12, iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }

    /// Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
    /// Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/swift/enum/c:@E@CBCharacteristicWriteType), so be sure to check this out before usage of the method.
    /// - parameter data: Data that'll be written  written to `Characteristic` instance
    /// - parameter forCharacteristic: `Characteristic` instance to write value to.
    /// - parameter type: Type of write operation. Possible values: `.WithResponse`, `.WithoutResponse`
    /// - returns: Observable that emition depends on `CBCharacteristicWriteType` passed to the function call.
    /// Behavior is following:
    /// - `withResponse` -  Observable emits `Next` with `Characteristic` instance write was confirmed without any errors.
    /// Immediately after that `Complete` is called. If any problem has happened, errors are emitted.
    /// - `withoutResponse` - Observable emits `Next` with `Characteristic` instance once write was called.
    /// Immediately after that `.Complete` is called. Result of this call is not checked, so as a user you are not sure
    /// if everything completed successfully. Errors are not emitted. It ensures that peripheral is ready to write
    /// without response by listening to the proper delegate method
    public func writeValue(_ data: Data,
                           for characteristic: Characteristic,
                           type: CBCharacteristicWriteType) -> Single<Characteristic> {
        let writeOperationPerformingAndListeningObservable = { [weak self] (observable: Observable<Characteristic>)
            -> Observable<Characteristic> in
            guard let strongSelf = self else { return Observable.error(BluetoothError.destroyed) }
            return strongSelf.ensureValidPeripheralStateAndCallIfSucceeded(
                for: observable,
                postSubscriptionCall: { [weak self] in
                    self?.peripheral.writeValue(data, for: characteristic.characteristic, type: type)
                }
            )
        }
        switch type {
        case .withoutResponse:
            return Observable<Characteristic>.deferred { [weak self] in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return strongSelf.monitorWriteWithoutResponseReadiness()
                    .map { _ in true }
                    .startWith(strongSelf.canSendWriteWithoutResponse)
                    .filter { $0 }
                    .take(1)
                    .flatMap { _ in
                        writeOperationPerformingAndListeningObservable(Observable.just(characteristic))
                    }
            }.asSingle()
        case .withResponse:
            return writeOperationPerformingAndListeningObservable(monitorWrite(for: characteristic).take(1))
                .asSingle()
        }
    }

    /// Function that allow to monitor value updates for `Characteristic` instance.
    /// - Parameter characteristic: Characteristic of which value changes should be monitored.
    /// - Returns: Observable that emits `Next` with `Characteristic` instance every time when value has changed.
    /// It's **infinite** stream, so `.Complete` is never called.
    public func monitorValueUpdate(for characteristic: Characteristic) -> Observable<Characteristic> {
        let observable = delegateWrapper
            .rx_didUpdateValueForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .map { (_, error) -> Characteristic in
                if let error = error {
                    throw BluetoothError.characteristicReadFailed(characteristic, error)
                }
                return characteristic
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that triggers read of current value of the `Characteristic` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Parameter characteristic: `Characteristic` to read value from
    /// - Returns: `Single` which emits `Next` with given characteristic when value is ready to read.
    public func readValue(for characteristic: Characteristic) -> Single<Characteristic> {
        let observable = monitorValueUpdate(for: characteristic).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.readValue(for: characteristic.characteristic)
            }
        ).asSingle()
    }

    /// Function that triggers set of notification state of the `Characteristic`.
    /// This change is called after subscribtion to `Observable` is made.
    /// - warning: This method is not responsible for emitting values every time that `Characteristic` value is changed.
    /// For this, refer to other method: `monitorValueUpdateForCharacteristic(_)`. These two are often called together.
    /// - parameter enabled: New value of notifications state. Specify `true` if you're interested in getting values
    /// - parameter forCharacteristic: Characterististic of which notification state needs to be changed
    /// - returns: `Single` which emits `Next` with Characteristic that state was changed.
    public func setNotifyValue(_ enabled: Bool,
                               for characteristic: Characteristic) -> Single<Characteristic> {
        let observable = delegateWrapper
            .rx_didUpdateNotificationStateForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .map { (_, error) -> Characteristic in
                if let error = error {
                    throw BluetoothError.characteristicNotifyChangeFailed(characteristic, error)
                }
                return characteristic
            }
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.setNotifyValue(enabled, for: characteristic.characteristic)
            }
        ).asSingle()
    }

    /// Function that triggers set of notification state of the `Characteristic`, and monitor for any incoming updates.
    /// Notification is set after subscribtion to `Observable` is made.
    /// - parameter characteristic: Characterististic on which notification should be made.
    /// - returns: `Observable` which emits `Next`, when characteristic value is updated.
    /// This is **infinite** stream of values.
    public func setNotificationAndMonitorUpdates(for characteristic: Characteristic)
        -> Observable<Characteristic> {
        return Observable
            .of(
                monitorValueUpdate(for: characteristic),
                setNotifyValue(true, for: characteristic)
                    .asObservable()
                    .ignoreElements()
                    .asObservable()
                    .map { _ in characteristic }
                    .subscribeOn(CurrentThreadScheduler.instance)
            )
            .merge()
    }

    // MARK: Descriptors
    /// Function that triggers descriptors discovery for characteristic
    /// If all of the descriptors are already discovered - these are returned without doing any underlying Bluetooth operations.
    /// - Parameter characteristic: `Characteristic` instance for which descriptors should be discovered.
    /// - Returns: `Single` that emits `Next` with array of `Descriptor` instances, once they're discovered.
    public func discoverDescriptors(for characteristic: Characteristic) -> Single<[Descriptor]> {
        if let descriptors = characteristic.descriptors {
            let resultDescriptors = descriptors.map { Descriptor(descriptor: $0.descriptor, characteristic: characteristic) }
            return ensureValidPeripheralState(for: .just(resultDescriptors)).asSingle()
        }
        let observable = delegateWrapper
            .rx_didDiscoverDescriptorsForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .map { (cbCharacteristic, error) -> [Descriptor] in
                if let descriptors = cbCharacteristic.descriptors, error == nil {
                    return descriptors.map {
                        Descriptor(descriptor: $0, characteristic: characteristic) }
                }
                throw BluetoothError.descriptorsDiscoveryFailed(characteristic, error)
            }

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.discoverDescriptors(for: characteristic.characteristic)
            }
        ).asSingle()
    }

    /// Function that allow to monitor writes that happened for descriptor.
    /// - Parameter descriptor: Descriptor of which value writes should be monitored.
    /// - Returns: Observable that emits `Next` with `Descriptor` instance every time when write has happened.
    /// It's **infinite** stream, so `.Complete` is never called.
    public func monitorWrite(for descriptor: Descriptor) -> Observable<Descriptor> {
        let observable = delegateWrapper
            .rx_didWriteValueForDescriptor
            .filter { $0.0 == descriptor.descriptor }
            .map { (_, error) -> Descriptor in
                if let error = error {
                    throw BluetoothError.descriptorWriteFailed(descriptor, error)
                }
                return descriptor
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that allow to monitor value updates for `Descriptor` instance.
    /// - Parameter descriptor: Descriptor of which value changes should be monitored.
    /// - Returns: Observable that emits `Next` with `Descriptor` instance every time when value has changed.
    /// It's **infinite** stream, so `.Complete` is never called.
    public func monitorValueUpdate(for descriptor: Descriptor) -> Observable<Descriptor> {
        let observable = delegateWrapper.rx_didUpdateValueForDescriptor
            .filter { $0.0 == descriptor.descriptor }
            .map { (_, error) -> Descriptor in
                if let error = error {
                    throw BluetoothError.descriptorReadFailed(descriptor, error)
                }
                return descriptor
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that triggers read of current value of the `Descriptor` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Parameter descriptor: `Descriptor` to read value from
    /// - Returns: `Single` which emits `Next` with given descriptor when value is ready to read.
    public func readValue(for descriptor: Descriptor) -> Single<Descriptor> {
        let observable = monitorValueUpdate(for: descriptor).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.readValue(for: descriptor.descriptor) }
        )
        .asSingle()
    }

    /// Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
    /// - Parameter data: `Data` that'll be written to `Descriptor` instance
    /// - Parameter descriptor: `Descriptor` instance to write value to.
    /// - Returns: `Single` that emits `Next` with `Descriptor` instance, once value is written successfully.
    public func writeValue(_ data: Data, for descriptor: Descriptor) -> Single<Descriptor> {
        let monitorWrite = self.monitorWrite(for: descriptor).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: monitorWrite,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.writeValue(data, for: descriptor.descriptor) }
        )
        .asSingle()
    }

    func ensureValidPeripheralStateAndCallIfSucceeded<T>(for observable: Observable<T>,
                                                         postSubscriptionCall call: @escaping () -> Void
    ) -> Observable<T> {
        let operation = Observable<T>.deferred {
            call()
            return .empty()
        }
        return ensureValidPeripheralState(for: Observable.merge([observable, operation]))
    }

    /// Function that merges given observable with error streams of invalid Central Manager states.
    /// - parameter observable: `Observable` to be transformed
    /// - returns: Source `Observable` which listens on state chnage errors as well
    func ensureValidPeripheralState<T>(for observable: Observable<T>) -> Observable<T> {
        return Observable<T>.absorb(
            manager.ensurePeripheralIsConnected(self),
            manager.ensure(.poweredOn, observable: observable)
        )
    }

    /// Function that triggers read of `Peripheral` RSSI value. Read is called after subscription to `Observable` is made.
    /// - returns: `Single` that emits tuple: `(Peripheral, Int)` once new RSSI value is read.
    /// `Int` is new RSSI value, `Peripheral` is returned to allow easier chaining.
    public func readRSSI() -> Single<(Peripheral, Int)> {
        let observable = delegateWrapper.rx_didReadRSSI
            .take(1)
            .map { [weak self] (rssi, error) -> (Peripheral, Int) in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                if let error = error {
                    throw BluetoothError.peripheralRSSIReadFailed(strongSelf, error)
                }
                return (strongSelf, rssi)
            }

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.readRSSI()
            }
        ).asSingle()
    }

    /// Function that allow user to monitor incoming `name` property changes of `Peripheral` instance.
    /// - returns: `Observable` that emits tuples: `(Peripheral, String?)` when name has changed.
    ///    It's `optional String` because peripheral could also lost his name.
    ///    It's **infinite** stream of values, so `.Complete` is never emitted.
    public func monitorNameUpdate() -> Observable<(Peripheral, String?)> {
        let observable = delegateWrapper.rx_didUpdateName.map { [weak self] name -> (Peripheral, String?) in
            guard let strongSelf = self else { throw BluetoothError.destroyed }
            return (strongSelf, name)
        }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that allow to monitor incoming service modifications for `Peripheral` instance.
    /// In case you're interested what exact changes might occur - please refer to
    /// [Apple Documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/#//apple_ref/occ/intfm/CBPeripheralDelegate/peripheral:didModifyServices:)
    ///
    /// - returns: `Observable` that emits tuples: `(Peripheral, [Service])` when services were modified.
    ///    It's **infinite** stream of values, so `.Complete` is never emitted.
    public func monitorServicesModification() -> Observable<(Peripheral, [Service])> {
        let observable = delegateWrapper.rx_didModifyServices
            .map { [weak self] services -> [Service] in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return services.map { Service(peripheral: strongSelf, service: $0) } }
            .map { [weak self] services -> (Peripheral, [Service]) in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return (strongSelf, services)
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Resulting observable emits next element if call to `writeValue:forCharacteristic:type:` has failed,
    /// to indicate when peripheral is again ready to send characteristic value updates again.
    public func monitorWriteWithoutResponseReadiness() -> Observable<Void> {
        return delegateWrapper.rx_peripheralReadyToSendWriteWithoutResponse
    }
}

extension Peripheral: Equatable {}

/**
 Compare two peripherals which are the same when theirs identifiers are equal.

 - parameter lhs: First peripheral to compare
 - parameter rhs: Second peripheral to compare
 - returns: True if both peripherals are the same
 */
public func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
}
