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

/**
 Core Bluetooth implementation of RxCentralManagerType. This is a lightweight wrapper which allows
 to hide all implementation details.
 */
class RxCBCentralManager: RxCentralManagerType {
	private let centralManager: CBCentralManager
	private let internalDelegate = InternalDelegate()

	/**
	 Create Core Bluetooth implementation of RxCentralManagerType which is used by BluetoothManager class.
	 User can specify on which thread all bluetooth events are collected.

	 - parameter queue: Dispatch queue on which callbacks are received.
	 */
    init(queue: dispatch_queue_t, options: [String : AnyObject]? = nil) {
		centralManager = CBCentralManager(delegate: internalDelegate, queue: queue, options: options)
	}

	@objc private class InternalDelegate: NSObject, CBCentralManagerDelegate {
		let didUpdateStateSubject = PublishSubject<CBCentralManagerState>()
		let willRestoreStateSubject = PublishSubject<[String: AnyObject]>()
		let didDiscoverPeripheralSubject = PublishSubject<(RxPeripheralType, [String: AnyObject], NSNumber)>()
		let didConnectPerihperalSubject = PublishSubject<RxPeripheralType>()
		let didFailToConnectPeripheralSubject = PublishSubject<(RxPeripheralType, NSError?)>()
		let didDisconnectPeripheral = PublishSubject<(RxPeripheralType, NSError?)>()

		@objc func centralManagerDidUpdateState(central: CBCentralManager) {
			didUpdateStateSubject.onNext(central.state)
		}

		@objc func centralManager(central: CBCentralManager, willRestoreState dict: [String: AnyObject]) {
			willRestoreStateSubject.onNext(dict)
		}

		@objc func centralManager(central: CBCentralManager,
			didDiscoverPeripheral peripheral: CBPeripheral,
			advertisementData: [String: AnyObject],
			RSSI: NSNumber) {
				didDiscoverPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), advertisementData, RSSI))
		}

		@objc func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
			didConnectPerihperalSubject.onNext(RxCBPeripheral(peripheral: peripheral))
		}

		@objc func centralManager(central: CBCentralManager,
			didFailToConnectPeripheral peripheral: CBPeripheral,
			error: NSError?) {
				didFailToConnectPeripheralSubject.onNext((RxCBPeripheral(peripheral: peripheral), error))
		}

		@objc func centralManager(central: CBCentralManager,
			didDisconnectPeripheral peripheral: CBPeripheral,
			error: NSError?) {
				didDisconnectPeripheral.onNext((RxCBPeripheral(peripheral: peripheral), error))
		}
	}

	/// Observable which infroms when central manager did change its state
	var rx_didUpdateState: Observable<CBCentralManagerState> {
		return internalDelegate.didUpdateStateSubject
	}
	/// Observable which infroms when central manager is about to restore its state
	var rx_willRestoreState: Observable<[String: AnyObject]> {
		return internalDelegate.willRestoreStateSubject
	}
	/// Observable which infroms when central manage discovered peripheral
	var rx_didDiscoverPeripheral: Observable<(RxPeripheralType, [String: AnyObject], NSNumber)> {
		return internalDelegate.didDiscoverPeripheralSubject
	}
	/// Observable which infroms when central manager connected to peripheral
	var rx_didConnectPeripheral: Observable<RxPeripheralType> {
		return internalDelegate.didConnectPerihperalSubject
	}
	/// Observable which infroms when central manager failed to connect to peripheral
	var rx_didFailToConnectPeripheral: Observable<(RxPeripheralType, NSError?)> {
		return internalDelegate.didFailToConnectPeripheralSubject
	}
	/// Observable which infroms when central manager disconnected from peripheral
	var rx_didDisconnectPeripheral: Observable<(RxPeripheralType, NSError?)> {
		return internalDelegate.didDisconnectPeripheral
	}

	/// Current central manager state
	var state: CBCentralManagerState {
		return centralManager.state
	}

	/// Current continuous state of Central Manager
	var rx_state: Observable<CBCentralManagerState> {
		return centralManager
			.rx_observeWeakly(CBCentralManagerState.self, "state")
			.flatMap {
                state -> Observable<CBCentralManagerState> in
				guard let state = state else {
					return Observable.error(BluetoothError.BluetoothInUnknownState)
				}
				return Observable.just(state)
            }
            .replay(1)
	}

	/**
	 Start scanning for peripherals with specified services. Results will be available on rx_didDiscoverPeripheral
	 observable.

	 - parameter serviceUUIDs: Services which peripherals needs to implement. When nil is passed all
	 available peripherals will be discovered.
	 - parameter options: Central Manager specific options for scanning
	 */
	func scanForPeripheralsWithServices(serviceUUIDs: [CBUUID]?, options: [String: AnyObject]?) {
		return centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: options)
	}

	/**
	 Connect to specified peripheral. If connection is successful peripheral will be emitted in rx_didConnectPeripheral
	 observable. In case of any error it will be emitted on rx_didFailToConnectPeripheral.

	 - parameter peripheral: Peripheral to connect to.
	 - parameter options: Central Manager specific connection options.
	 */
	func connectPeripheral(peripheral: RxPeripheralType, options: [String: AnyObject]?) {
		return centralManager.connectPeripheral((peripheral as! RxCBPeripheral).peripheral, options: options)
	}

	/**
	 Cancel peripheral connection. If successful observable rx_didDisconnectPeripheral will emit disconnected
	 peripheral with NSError set to nil.

	 - parameter peripheral: Peripheral to be disconnected.
	 */
	func cancelPeripheralConnection(peripheral: RxPeripheralType) {
		return centralManager.cancelPeripheralConnection((peripheral as! RxCBPeripheral).peripheral)
	}

	/// Abort peripheral scanning
	func stopScan() {
		return centralManager.stopScan()
	}

	/**
	 Retrieve list of connected peripherals which implement specified services. Peripherals which meet criteria
	 will be emitted in by returned observable after subscription.

	 - parameter serviceUUIDs: List of services which need to be implemented by retrieved peripheral.
	 - returns: Observable wich emits connected peripherals.
	 */
	func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> Observable<[RxPeripheralType]> {
		return Observable.just(centralManager.retrieveConnectedPeripheralsWithServices(serviceUUIDs).map {
			RxCBPeripheral(peripheral: $0)
		})
	}

	/**
	 Retrieve peripherals with specified identifiers.

	 - parameter identifiers: List of identifiers of peripherals for which we are looking for.
	 - returns: Observable which emits peripherals with specified identifiers.
	 */
	func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> Observable<[RxPeripheralType]> {
		return Observable.just(centralManager.retrievePeripheralsWithIdentifiers(identifiers).map {
			RxCBPeripheral(peripheral: $0)
		})
	}
}
