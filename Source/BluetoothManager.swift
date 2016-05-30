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
import RxCocoa
import CoreBluetooth

// swiftlint:disable line_length

/**
 BluetoothManager is a class implementing ReactiveX API which wraps all Core Bluetooth Manager's functions allowing to
 discover, connect to remote peripheral devices and more. It's using thin layer behind `RxCentralManagerType` protocol which is
 implemented by `RxCBCentralManager` and should not be used directly by the user of a RxBluetoothKit library.

 You can start using this class by discovering available services of nearby peripherals. Before calling any
 public `BluetoothManager`'s functions you should make sure that Bluetooth is turned on and powered on. It can be done
 by calling and observing returned value of `monitorState()` and then chaining it with `scanForPeripherals(_:options:)`:

 bluetoothManager.rx_state
 .filter { $0 == .PoweredOn }
 .take(1)
 .flatMap { manager.scanForPeripherals(nil) }

 As a result you will receive `ScannedPeripheral` which contains `Peripheral` object, `AdvertisementData` and
 peripheral's RSSI registered during discovery. You can then `connectToPeripheral(_:options:)` and do other operations.

 - seealso: `Peripheral`
 */
public class BluetoothManager {

	/// Implementation of Central Manager
	private let centralManager: RxCentralManagerType

	/// Queue on which all observables are serialised if needed
	private let subscriptionQueue: SerializedSubscriptionQueue

	/// Lock which should be used before accessing any internal structures
	private let lock = NSLock()

	/// Queue of scan operations which are waiting for an execution
	private var scanQueue: [ScanOperation] = []
	private let disposeBag = DisposeBag()

	// MARK: Initialization

	/**
	 Creates new `BluetoothManager` instance with specified implementation of `RxCentralManagerType` protocol which will be
	 used by this class. Most of a time `RxCBCentralManager` should be chosen by the user.

	 - parameter centralManager: Implementation of `RxCentralManagerType` protocol used by this class.
	 - parameter queueScheduler: Scheduler on which all serialised operations are executed (such as scans). By default
	 main thread is used.
	 */
	init(centralManager: RxCentralManagerType,
		queueScheduler: SchedulerType = ConcurrentMainScheduler.instance) {
			self.centralManager = centralManager
			self.subscriptionQueue = SerializedSubscriptionQueue(scheduler: queueScheduler)
	}

	/**
	 Creates new `BluetoothManager` instance. By default all operations and events are executed and received on
	 main thread.

	 - warning: If you pass background queue to the method make sure to observe results on main thread for UI related
	 code.

	 - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.

     - parameter options: An optional dictionary containing initialization options for a central manager.
     For more info about it please refer to [`Central Manager initialization options`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
	 */
	convenience public init(queue: dispatch_queue_t = dispatch_get_main_queue(),
	                        options: [String : AnyObject]? = nil) {
		self.init(centralManager: RxCBCentralManager(queue: queue),
			queueScheduler: ConcurrentDispatchQueueScheduler(queue: queue))
	}

	// MARK: Scanning

	/**
	 Scans for `Peripheral`s after subscription to returned observable. First parameter `serviceUUIDs` is
	 an array of `Service` UUIDs which needs to be implemented by a peripheral to be discovered. If user don't want to
	 filter any peripherals, `nil` can be used instead. Additionally dictionary of
	 [`CBCentralManager` specific options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options)
	 can be passed to allow further customisation.

	 Scans by default are infinite streams of `ScannedPeripheral` structures which need to be stopped by the user. For
	 example this can be done by limiting scanning to certain number of peripherals or time:

	 bluetoothManager.scanForPeripherals(nil)
        .timeout(3.0, timeoutScheduler)
        .take(2)

	 If different scan is currently in progress and peripherals needed by a user can be discovered by it, new scan is
	 shared. Otherwise scan is queued on thread specified in `init(centralManager:queueScheduler:)` and will be executed
	 when other scans finished with complete/error event or were unsubscribed.

	 As a result you will receive `ScannedPeripheral` which contains `Peripheral` object, `AdvertisementData` and
	 peripheral's RSSI registered during discovery. You can then `connectToPeripheral(_:options:)` and do other
	 operations.

	 - seealso: `Peripheral`

	 - parameter serviceUUIDs: Services of peripherals to search for. Nil value will accept all peripherals.
	 - parameter options: Optional scanning options.
	 - returns: Infinite stream of scanned peripherals.
	 */
	public func scanForPeripherals(serviceUUIDs: [CBUUID]?, options: [String: AnyObject]? = nil)
		-> Observable<ScannedPeripheral> {

			return Observable.deferred {
				let observable: Observable<ScannedPeripheral> = { Void -> Observable<ScannedPeripheral> in
					// If it's possible use existing scan - take if from the queue
					self.lock.lock(); defer { self.lock.unlock() }
					if let elem = self.scanQueue.findElement({ $0.acceptUUIDs(serviceUUIDs) }) {
						guard serviceUUIDs != nil else {
							return elem.observable
						}

						// When binding to existing scan we need to make sure that services are
						// filtered properly
						return elem.observable.filter { scannedPeripheral in
							if let services = scannedPeripheral.advertisementData.serviceUUIDs {
								return Set(services).isSupersetOf(serviceUUIDs!)
							}
							return false
						}
					}

					let scanOperationBox = MutableBox<ScanOperation>()

					// Create new scan which will be processed in a queue
					let operation = Observable.create { (element: AnyObserver<ScannedPeripheral>) -> Disposable in

						// Observable which will emit next element, when peripheral is discovered.
						let disposable = self.centralManager.rx_didDiscoverPeripheral
							.map { (peripheral, advertisment, rssi) -> ScannedPeripheral in
								let peripheral = Peripheral(manager: self, peripheral: peripheral)
								let advertismentData = AdvertisementData(advertisementData: advertisment)
								return ScannedPeripheral(peripheral: peripheral,
									advertisementData: advertismentData, RSSI: rssi)
						}
							.subscribe(element)

						// Start scanning for devices
						self.centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: options)

						return AnonymousDisposable {
							// When disposed, stop all scans, and remove scanning operation from queue
							self.centralManager.stopScan()
							disposable.dispose()
							do { self.lock.lock(); defer { self.lock.unlock() }
								if let index = self.scanQueue.indexOf({ $0 == scanOperationBox.value! }) {
									self.scanQueue.removeAtIndex(index)
								}
							}
						}
					}
						.queueSubscribeOn(self.subscriptionQueue)
						.publish()
						.refCount()

					let scanOperation = ScanOperation(UUIDs: serviceUUIDs, observable: operation)
					self.scanQueue.append(scanOperation)

					scanOperationBox.value = scanOperation
					return operation
				}()
				// Allow scanning as long as bluetooth is powered on
				return self.ensureState(.PoweredOn, observable: observable)
			}
	}

	// MARK: State

	/**
	 Continuous state of `BluetoothManager` instance described by [`CBCentralManagerState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/c/tdef/CBCentralManagerState).

	 - returns: Observable that emits `Next` immediately after subscribtion with current state of Bluetooth. Later,
     whenever state changes events are emitted. Observable is infinite : doesn't generate `Complete`.
	 */
	public var rx_state: Observable<CBCentralManagerState> {
		return self.centralManager.rx_didUpdateState.startWith(self.centralManager.state)
	}

	/**
	 Current state of `BluetoothManager` instance described by [`CBCentralManagerState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/c/tdef/CBCentralManagerState).

	 - returns: Current state of `BluetoothManager` as `CBCentralManagerState`.
	 */
	public var state: CBCentralManagerState {
		return centralManager.state
	}

	/**
	 After subscription emits current state of `BluetoothManager` instance described by [`CBCentralManagerState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/c/tdef/CBCentralManagerState). Later, whenever state changes next element is emitted.

	 - returns: Observable emitting state of `BluetoothManager` as `CBCentralManagerState`.
	 */
	@available( *, deprecated, message = "Use rx_state property instead.")
	public func monitorState() -> Observable<CBCentralManagerState> {
		return Observable.deferred {
			return self.centralManager.rx_didUpdateState.startWith(self.centralManager.state)
		}
	}

	/**
	 Emits state changes of `BluetoothManager` instance described by [`CBCentralManagerState`](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/c/tdef/CBCentralManagerState).

	 - returns: Observable emitting state of `BluetoothManager` as `CBCentralManagerState`.
	 */
	@available( *, deprecated, message = "Use rx_state property instead.")
	public func monitorStateChange() -> Observable<CBCentralManagerState> {
		return self.centralManager.rx_didUpdateState
	}

	// MARK: Peripheral's Connection Management

	/**
	 Establishes connection with `Peripheral` after subscription to returned observable. It's user responsibility
	 to close connection with `cancelConnectionToPeripheral(_:)` after subscription was completed. Unsubscribing from
	 returned observable cancels connection attempt. By default observable is waiting infinitely for successful
	 connection.

	 Additionally you can pass optional [dictionary](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Connection_Options)
	 to customise the behaviour of connection.

	 - parameter peripheral: The `Peripheral` to which `BluetoothManager` is attempting to connect.
	 - parameter options: Dictionary to customise the behaviour of connection.
	 - returns: Observable which emits next and complete events after connection is established.
	 */
	public func connectToPeripheral(peripheral: Peripheral, options: [String: AnyObject]? = nil)
		-> Observable<Peripheral> {

			let success = centralManager.rx_didConnectPeripheral
				.filter { $0 == peripheral.peripheral }
				.take(1)
				.map { _ in return peripheral }

			let error = centralManager.rx_didFailToConnectPeripheral
				.filter { $0.0 == peripheral.peripheral }
				.take(1)
				.flatMap { (peripheral, error) -> Observable<Peripheral> in
					Observable.error(BluetoothError.PeripheralConnectionFailed(
						Peripheral(manager: self, peripheral: peripheral), error))
			}

			let observable = Observable<Peripheral>.create { observer in
				if let error = BluetoothError.errorFromState(self.centralManager.state) {
					observer.onError(error)
					return NopDisposable.instance
				}

				guard !peripheral.isConnected else {
					observer.onNext(peripheral)
					observer.onCompleted()
					return NopDisposable.instance
				}
				let disposable = success.amb(error).subscribe(observer)
				self.centralManager.connectPeripheral(peripheral.peripheral, options: options)
				return AnonymousDisposable {
					if !peripheral.isConnected {
						self.centralManager.cancelPeripheralConnection(peripheral.peripheral)
						disposable.dispose()
					}
				}
			}

			return ensureState(.PoweredOn, observable: observable)
	}

	/**
	 Cancels an active or pending local connection to a `Peripheral` after observable subscription. It is not guaranteed
	 that physical connection will be closed immediately as well and all pending commands will not be executed.

	 - parameter peripheral: The `Peripheral` to which the `BluetoothManager` is either trying to
	 connect or has already connected.
	 - returns: Observable which emits next and complete events when peripheral successfully cancelled connection.
	 */
	public func cancelConnectionToPeripheral(peripheral: Peripheral) -> Observable<Peripheral> {
		let observable = Observable<Peripheral>.create { observer in
			let disposable = self.monitorPeripheralDisconnection(peripheral).take(1).subscribe(observer)
			self.centralManager.cancelPeripheralConnection(peripheral.peripheral)
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
		return ensureState(.PoweredOn, observable: observable)
	}

	// MARK: Retrieving Lists of Peripherals

	/**
	 Returns observable list of the `Peripheral`s which are currently connected to the `BluetoothManager` and contain
	 all of the specified `Service`'s UUIDs.

	 - parameter serviceUUIDs: A list of `Service` UUIDs
	 - returns: Observable which emits retrieved `Peripheral`s. They are in connected state and contain all of the
	 `Service`s with UUIDs specified in the `serviceUUIDs` parameter. Just after that complete event is emitted
	 */
	public func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> Observable<[Peripheral]> {
		let observable = Observable<[Peripheral]>.deferred {
			return self.centralManager.retrieveConnectedPeripheralsWithServices(serviceUUIDs).map {
				(peripheralTable: [RxPeripheralType]) ->
				[Peripheral] in peripheralTable.map {
					Peripheral(manager: self, peripheral: $0)
				}
			}
		}
		return ensureState(.PoweredOn, observable: observable)
	}

	/**
	 Returns observable list of `Peripheral`s by their identifiers which are known to `BluetoothManager`.

	 - parameter identifiers: List of `Peripheral`'s identifiers which should be retrieved.
	 - returns: Observable which emits next and complete events when list of `Peripheral`s are retrieved.
	 */
	public func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[Peripheral]> {
		let observable = Observable<[Peripheral]>.deferred {
			return self.centralManager.retrievePeripheralsWithIdentifiers(identifiers).map {
				(peripheralTable: [RxPeripheralType]) ->
				[Peripheral] in peripheralTable.map {
					Peripheral(manager: self, peripheral: $0)
				}
			}
		}
		return ensureState(.PoweredOn, observable: observable)
	}

	// MARK:  Internal functions
    
	/**
	 Ensure that `state` is and will be the only state of `BluetoothManager` during subscription.
	 Otherwise error is emitted.

	 - parameter state: `CBCentralManagerState` which should be present during subscription.
	 - parameter observable: Observable into which potential errors should be merged.
	 - returns: New observable which merges errors with source observable.
	 */
	func ensureState<T>(state: CBCentralManagerState, observable: Observable<T>) -> Observable<T> {
		let statesObservable = rx_state
			.filter { $0 != state && BluetoothError.errorFromState($0) != nil }
			.map { state -> T in throw BluetoothError.errorFromState(state)! }
		return Observable.absorb(statesObservable, observable)
	}

	/**
	 Ensure that specified `peripheral` is connected during subscription.

	 - parameter peripheral: `Peripheral` which should be connected during subscription.
	 - returns: Observable which emits error when `peripheral` is disconnected during subscription.
	 */
	func ensurePeripheralIsConnected<T>(peripheral: Peripheral) -> Observable<T> {
		return Observable.deferred {
			if !peripheral.isConnected {
				return Observable.error(BluetoothError.PeripheralDisconnected(peripheral, nil))
			}
			return self.centralManager.rx_didDisconnectPeripheral
				.filter { $0.0 == peripheral.peripheral }
				.flatMap { (_, error) -> Observable<T> in
					return Observable.error(BluetoothError.PeripheralDisconnected(peripheral, error))
			}
		}
	}

	/**
	 Emits `Peripheral` instance when it's disconnected.

	 - Parameter peripheral: `Peripheral` which is monitored for disconnection.
	 - Returns: Observable which emits next events when `peripheral` was disconnected.
	 */
	func monitorPeripheralDisconnection(peripheral: Peripheral) -> Observable<Peripheral> {
		return centralManager
			.rx_didDisconnectPeripheral
			.filter { $0.0 == peripheral.peripheral }
			.flatMap { (_, error) -> Observable<Peripheral> in
				return Observable.just(peripheral)
		}
	}

    /**
     Emits `RestoredState` instance, when state of `BluetoothManager` has been restored
     - Returns: Observable which emits next events state has been restored
     */
    func listenOnRestoredState() -> Observable<RestoredState> {
        return centralManager
            .rx_willRestoreState
            .take(1)
            .map { RestoredState(restoredStateDictionary: $0, bluetoothManager: self) }
    }
}
