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

// swiftlint:disable line_length

/**
 Peripheral is a class implementing ReactiveX API which wraps all Core Bluetooth functions
 allowing to talk to peripheral like discovering characteristics, services and all of the read/write calls.
 */
public class Peripheral {

	/// Implementation of peripheral
	let peripheral: RxPeripheralType

	/**
	 Continuous value indicating if peripheral is in connected state.
	 */
	public var rx_isConnected: Observable<Bool> {
		return peripheral.rx_state.map { $0 == .Connected }
	}

	/**
	 Value indicating if peripheral is currently in connected state.
	 */
	public var isConnected: Bool {
		return peripheral.state == .Connected
	}

	/**
	 Continuous state of `Peripheral` instance described by [`CBPeripheralState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/c/tdef/CBPeripheralState).

     - returns: Current state of `Peripheral` as `CBPeripheralState`immediately after subscribtion with current state of
     Peripheral. Later, whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
	 */
	public var rx_state: Observable<CBPeripheralState> {
		return peripheral.rx_state
	}

	/**
	 Current state of `Peripheral` instance described by [`CBPeripheralState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/c/tdef/CBPeripheralState).

	 - returns: Current state of `Peripheral` as `CBPeripheralState`.
	 */
	public var state: CBPeripheralState {
		return peripheral.state
	}

	/**
	 Current name of `Peripheral` instance. Analogous to   [`name`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/c/tdef/name) of `CBPeripheral`.
	 */
	public var name: String? {
		return peripheral.name
	}

	/**
	 Unique identifier of `Peripheral` instance. Assigned once peripheral is discovered by the system.
	 */
	public var identifier: NSUUID {
		return peripheral.identifier
	}

	/**
	 A list of services that have been discovered. Analogous to   [`services`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/occ/instp/CBPeripheral/services) of `CBPeripheral`.
	 */
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
	 Establishes local connection to the peripheral.
	 For more information look into `BluetoothManager.connectToPeripheral(_:options:)` because this method calls it directly.
	 - Parameter peripheral: The `Peripheral` to which `BluetoothManager` is attempting to connect.
	 - Parameter options: Dictionary to customise the behaviour of connection.
	 - Returns: Observation which emits next event after connection is established
	 */
	public func connect(options: [String: AnyObject]? = nil) -> Observable<Peripheral> {
		return manager.connectToPeripheral(self, options: options)
	}

	/**
	 Cancels an active or pending local connection to a `Peripheral` after observable subscription. It is not guaranteed
	 that physical connection will be closed immediately as well and all pending commands will not be executed.

	 - returns: Observable which emits next and complete events when peripheral successfully cancelled connection.
	 */
	public func cancelConnection() -> Observable<Peripheral> {
		return manager.cancelConnectionToPeripheral(self)
	}

	/**
	 Triggers discover of specified services of peripheral. If the servicesUUIDs parameter is nil, all the available services of the peripheral are returned; setting the parameter to nil is considerably slower and is not recommended.

	 - Parameter serviceUUIDs: An array of [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/) objects that you are interested in. Here, each [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/) object represents a UUID that identifies the type of service you want to discover.
	 - Returns: Observable that emits `Next` with array of `Service` instances, once they're discovered.
	 Immediately after that `.Complete` is emitted.
	 */
	public func discoverServices(serviceUUIDs: [CBUUID]?) -> Observable<[Service]> {
		let observable = peripheral.rx_didDiscoverServices
			.flatMap {
				(services, error) -> Observable<[Service]> in
				if let discoveredServices = services {
					let mapped = discoveredServices.map { Service(peripheral: self, service: $0) }
					guard let identifiers = serviceUUIDs else { return Observable.just(mapped) }
					let uuids = discoveredServices.map { $0.uuid }
					if Set(uuids) == Set(identifiers) {
						return Observable.just(mapped)
					}
					return Observable.empty()
				}
				return Observable.error(BluetoothError.ServicesDiscoveryFailed(self, error))
            }
			.take(1)

		return Observable.create { observer in
			let disposable = self.ensureValidPeripheralState(observable).subscribe(observer)
			self.peripheral.discoverServices(serviceUUIDs)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that triggers included services discovery for specified services. Discovery is called after
	 subscribtion to `Observable` is made.
	 - Parameter includedServiceUUIDs: Identifiers of included services that should be discovered. If `nil` - all of the
	 included services will be discovered. If you'll pass empty array - none of them will be discovered.
	 - Parameter forService: Service of which included services should be discovered.
	 - Returns: Observable that emits `Next` with array of `Service` instances, once they're discovered.
	 Immediately after that `.Complete` is emitted.
	 */
	public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?,
		forService service: Service) -> Observable<[Service]> {
			let observable = peripheral
				.rx_didDiscoverIncludedServicesForService
				.filter { $0.0 == service.service }
				.flatMap { (service, error) -> Observable<[Service]> in
					guard let includedServices = service.includedServices where error == nil else {
						return Observable.error(BluetoothError.IncludedServicesDiscoveryFailed(self, error))
					}
					let mapped = includedServices.map { Service(peripheral: self, service: $0) }
					guard includedServiceUUIDs != nil else { return Observable.just(mapped) }
					return Observable
						.just(mapped.filter { self.shouldBeIdentifierIncluded($0.UUID, forIdentifiers: includedServiceUUIDs) }) }
				.take(1)

			return Observable.create { observer in
				let disposable = self.ensureValidPeripheralState(observable).subscribe(observer)
				self.peripheral.discoverIncludedServices(includedServiceUUIDs, forService: service.service)
				return AnonymousDisposable {
					disposable.dispose()
				}
			}
	}

	// MARK: Characteristics
	/**
	 Function that triggers characteristics discovery for specified Services and identifiers. Discovery is called after
	 subscribtion to `Observable` is made.
	 - Parameter identifiers: Identifiers of characteristics that should be discovered. If `nil` - all of the
	 characteristics will be discovered. If you'll pass empty array - none of them will be discovered.
	 - Parameter service: Service of which characteristics should be discovered.
	 - Returns: Observable that emits `Next` with array of `Characteristic` instances, once they're discovered.
	 Immediately after that `.Complete` is emitted.
	 */
	public func discoverCharacteristics(identifiers: [CBUUID]?, service: Service) -> Observable<[Characteristic]> {
		let observable = peripheral
			.rx_didDiscoverCharacteristicsForService
			.filter { $0.0 == service.service }
			.flatMap { (cbService, error) -> Observable<[Characteristic]> in
				guard let characteristics = cbService.characteristics where error == nil else {
					return Observable.error(BluetoothError.CharacteristicsDiscoveryFailed(service, error))
				}
				let mapped = characteristics.map { Characteristic(characteristic: $0, service: service) }
				guard identifiers != nil else { return Observable.just(mapped) }
				return Observable.just(mapped
						.filter { self.shouldBeIdentifierIncluded($0.UUID, forIdentifiers: identifiers) })
            }
			.take(1)

		return Observable.create { observer in
			let disposable = self.ensureValidPeripheralState(observable).subscribe(observer)
			self.peripheral.discoverCharacteristics(identifiers, forService: service.service)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that allow to monitor writes that happened for characteristic.
	 - Parameter characteristic: Characteristic of which value writes should be monitored.
	 - Returns: Observable that emits `Next` with `Characteristic` instance every time when write has happened.
	 It's **infinite** stream, so `.Complete` is never called.
	 */
	public func monitorWriteForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
		return peripheral
			.rx_didWriteValueForCharacteristic
			.filter { return $0.0 == characteristic.characteristic }
			.flatMap { (rxCharacteristic, error) -> Observable<Characteristic> in
				if let error = error {
					return Observable.error(BluetoothError.CharacteristicWriteFailed(characteristic, error))
				}
				return Observable.just(characteristic)
            }
	}

	/**
	 Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
	 Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/swift/enum/c:@E@CBCharacteristicWriteType), so be sure to check this out before usage of the method.
	 - parameter data: Data that'll be written  written to `Characteristic` instance
	 - parameter forCharacteristic: `Characteristic` instance to write value to.
	 - parameter type: Type of write operation. Possible values: `.WithResponse`, `.WithoutResponse`
	 - returns: Observable that emition depends on `CBCharacteristicWriteType` passed to the function call.
	 Behavior is following:

	 - `WithResponse` -  Observable emits `Next` with `Characteristic` instance write was confirmed without any errors.
	 Immediately after that `Complete` is called. If any problem has happened, errors are emitted.
	 - `WithoutResponse` - Observable emits `Next` with `Characteristic` instance once write was called.
	 Immediately after that `.Complete` is called. Result of this call is not checked, so as a user you are not sure
	 if everything completed successfully. Errors are not emitted
	 */
	public func writeValue(data: NSData,
		forCharacteristic characteristic: Characteristic,
		type: CBCharacteristicWriteType) -> Observable<Characteristic> {
			return Observable.create { observer in
				let disposable: Disposable
				switch type {
				case .WithoutResponse:
					disposable = self.ensureValidPeripheralState(Observable.just(characteristic)).subscribe(observer)
					self.peripheral.writeValue(data, forCharacteristic: characteristic.characteristic, type: type)
				case .WithResponse:
					disposable = self.ensureValidPeripheralState(self.monitorWriteForCharacteristic(characteristic).take(1))
						.subscribe(observer)
					self.peripheral.writeValue(data, forCharacteristic: characteristic.characteristic, type: type)
				}
				return AnonymousDisposable {
					disposable.dispose()
				}
			}
	}

	/**
	 Function that allow to monitor value updates for `Characteristic` instance.
	 - Parameter characteristic: Characteristic of which value changes should be monitored.
	 - Returns: Observable that emits `Next` with `Characteristic` instance every time when value has changed.
	 It's **infinite** stream, so `.Complete` is never called.
	 */
	public func monitorValueUpdateForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
		let observable = peripheral
			.rx_didUpdateValueForCharacteristic
			.filter { $0.0 == characteristic.characteristic }
			.flatMap { (rxCharacteristic, error) -> Observable<Characteristic> in
				if let error = error {
					return Observable.error(BluetoothError.CharacteristicReadFailed(characteristic, error))
				}
				return Observable.just(characteristic)
            }
		return self.ensureValidPeripheralState(observable)
	}

	/**
	 Function that triggers read of current value of the `Characteristic` instance.
	 Read is called after subscription to `Observable` is made.
	 - Parameter characteristic: `Characteristic` to read value from
	 - Returns: Observable which emits `Next` with given characteristic when value is ready to read. Immediately after that
	 `.Complete` is emitted.
	 */
	public func readValueForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic> {
		return Observable.create { observer in
			let disposable = self.monitorValueUpdateForCharacteristic(characteristic).take(1).subscribe(observer)
			self.peripheral.readValueForCharacteristic(characteristic.characteristic)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that triggers set of notification state of the `Characteristic`.
	 This change is called after subscribtion to `Observable` is made.
	 - warning: This method is not responsible for emitting values every time that `Characteristic` value is changed.
	 For this, refer to other method: `monitorValueUpdateForCharacteristic(_)`. These two are often called together.
	 - parameter enabled: New value of notifications state. Specify `true` if you're interested in getting values
	 - parameter forCharacteristic: Characterististic of which notification state needs to be changed
	 - returns: Observable which emits `Next` with Characteristic that state was changed. Immediately after `.Complete`
	 is emitted
	 */
	public func setNotifyValue(enabled: Bool,
		forCharacteristic characteristic: Characteristic) -> Observable<Characteristic> {
			let observable = peripheral
				.rx_didUpdateNotificationStateForCharacteristic
				.filter { $0.0 == characteristic.characteristic }
				.take(1)
				.flatMap { (rxCharacteristic, error) -> Observable<Characteristic> in
					if let error = error {
						return Observable.error(BluetoothError.CharacteristicNotifyChangeFailed(characteristic, error))
					}
					return Observable.just(characteristic)
                }
			return Observable.create { observer in
				let disposable = self.ensureValidPeripheralState(observable).take(1).subscribe(observer)
				self.peripheral.setNotifyValue(enabled, forCharacteristic: characteristic.characteristic)
				return AnonymousDisposable {
					disposable.dispose()
				}
			}
	}

	/**
	 Function that triggers set of notification state of the `Characteristic`, and monitor for any incoming updates.
	 Notification is set after subscribtion to `Observable` is made.
	 - parameter characteristic: Characterististic on which notification should be made.
	 - returns: Observable which emits `Next`, when characteristic value is updated.
	 This is **infinite** stream of values.
	 */
	public func setNotificationAndMonitorUpdatesForCharacteristic(characteristic: Characteristic)
		-> Observable<Characteristic> {
			return Observable
				.of(
					monitorValueUpdateForCharacteristic(characteristic),
					setNotifyValue(true, forCharacteristic: characteristic)
						.ignoreElements()
						.subscribeOn(CurrentThreadScheduler.instance))
				.merge()
	}

	// MARK: Descriptors
	/**
	 Function that triggers descriptors discovery for characteristic
	 - Parameter characteristic: `Characteristic` instance for which descriptors should be discovered.
	 - Returns: Observable that emits `Next` with array of `Descriptor` instances, once they're discovered.
	 Immediately after that `.Complete` is emitted.
	 */
	public func discoverDescriptorsForCharacteristic(characteristic: Characteristic) -> Observable<[Descriptor]> {
		let observable = peripheral
			.rx_didDiscoverDescriptorsForCharacteristic
			.filter { $0.0 == characteristic.characteristic }
			.take(1)
			.flatMap { (cbCharacteristic, error) -> Observable<[Descriptor]> in
				if let descriptors = cbCharacteristic.descriptors where error == nil {
					return Observable.just(descriptors.map {
						Descriptor(descriptor: $0, characteristic: characteristic) })
				}
				return Observable.error(BluetoothError.DescriptorsDiscoveryFailed(characteristic, error))
            }

		return Observable.create { observer in
			let disposable = self.ensureValidPeripheralState(observable).subscribe(observer)
			self.peripheral.discoverDescriptorsForCharacteristic(characteristic.characteristic)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that allow to monitor writes that happened for descriptor.
	 - Parameter descriptor: Descriptor of which value writes should be monitored.
	 - Returns: Observable that emits `Next` with `Descriptor` instance every time when write has happened.
	 It's **infinite** stream, so `.Complete` is never called.
	 */
	public func monitorWriteForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
		return peripheral
			.rx_didWriteValueForDescriptor
			.filter { $0.0 == descriptor.descriptor }
			.flatMap { (rxDescriptor, error) -> Observable<Descriptor> in
				if let error = error {
					return Observable.error(BluetoothError.DescriptorWriteFailed(descriptor, error))
				}
				return Observable.just(descriptor)
            }
	}

	/**
	 Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
	 - Parameter data: `NSData` that'll be written to `Descriptor` instance
	 - Parameter descriptor: `Descriptor` instance to write value to.
	 - Returns: Observable that emits `Next` with `Descriptor` instance, once value is written successfully.
	 Immediately after that `.Complete` is emitted.
	 */
	public func writeValue(data: NSData, forDescriptor descriptor: Descriptor) -> Observable<Descriptor> {
		return Observable.create { observer in
			let disposable = self.ensureValidPeripheralState(self.monitorWriteForDescriptor(descriptor).take(1))
				.subscribe(observer)
			self.peripheral.writeValue(data, forDescriptor: descriptor.descriptor)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that allow to monitor value updates for `Descriptor` instance.
	 - Parameter descriptor: Descriptor of which value changes should be monitored.
	 - Returns: Observable that emits `Next` with `Descriptor` instance every time when value has changed.
	 It's **infinite** stream, so `.Complete` is never called.
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
	 Function that triggers read of current value of the `Descriptor` instance.
	 Read is called after subscription to `Observable` is made.
	 - Parameter descriptor: `Descriptor` to read value from
	 - Returns: Observable which emits `Next` with given descriptor when value is ready to read. Immediately after that
	 `.Complete` is emitted.
	 */
	public func readValueForDescriptor(descriptor: Descriptor) -> Observable<Descriptor> {
		return Observable.create { observer in
			let disposable = self.monitorValueUpdateForDescriptor(descriptor).take(1).subscribe(observer)
			self.peripheral.readValueForDescriptor(descriptor.descriptor)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that merges given observable with error streams of invalid Central Manager states.
	 - parameter observable: observation to be transformed
	 - returns: Source observable which listens on state chnage errors as well
	 */
	func ensureValidPeripheralState<T>(observable: Observable<T>) -> Observable<T> {
		return Observable.deferred {
			guard self.isConnected else {
				return Observable.error(BluetoothError.PeripheralDisconnected(self, nil))
			}
			return Observable.absorb(
				self.manager.ensurePeripheralIsConnected(self),
				self.manager.ensureState(.PoweredOn, observable: observable)
			)
		}
	}

	/**
	 Function that triggers read of `Peripheral` RSSI value. Read is called after subscription to `Observable` is made.
	 - returns: Observable that emits tuple: `(Peripheral, Int)` once new RSSI value is read, and just after that
	 `.Complete` event. `Int` is new RSSI value, `Peripheral` is returned to allow easier chaining.
	 */
	public func readRSSI() -> Observable<(Peripheral, Int)> {
		let observable = peripheral.rx_didReadRSSI
			.take(1)
			.flatMap { (rssi, error) -> Observable<(Peripheral, Int)> in
				if let error = error {
					return Observable.error(BluetoothError.PeripheralRSSIReadFailed(self, error))
				}
				return Observable.just(self, rssi)
		}
		return Observable.create { observer in
			let disposable = self.ensureValidPeripheralState(observable).subscribe(observer)
			self.peripheral.readRSSI()
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}

	/**
	 Function that allow user to monitor incoming `name` property changes of `Peripheral` instance.
	 - returns: Observable that emits tuples: `(Peripheral, String?)` when name has changed. It's `optional String` because peripheral could also lost his name. It's **infinite** stream of values, so `.Complete` is never emitted.
	 */
	public func monitorUpdateName() -> Observable<(Peripheral, String?)> {
		return peripheral.rx_didUpdateName.map { return (self, $0) }
	}

	/**
	 Function that allow to monitor incoming service modifications for `Peripheral` instance. In case you're interested what exact changes might occur - please refer to
	 [Apple Documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/#//apple_ref/occ/intfm/CBPeripheralDelegate/peripheral:didModifyServices:)

	 - returns: Observable that emits tuples: `(Peripheral, [Service])` when services were modified. It's **infinite** stream of values, so `.Complete` is never emitted.
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

extension Peripheral: Equatable { }

/**
 Compare two peripherals which are the same when theirs identifiers are equal.

 - parameter lhs: First peripheral to compare
 - parameter rhs: Second peripheral to compare
 - returns: True if both peripherals are the same
 */
public func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
	return lhs.peripheral == rhs.peripheral
}
