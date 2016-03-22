//
//  BluetoothManager.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 24/02/16.
//

import Foundation
import RxSwift
import CoreBluetooth

/**
 BluetoothManager is the main class which allows to use Bluetooth low energy to scan and connect to
 retrieved peripherals.
 */
public class BluetoothManager {

    /// Implementation of Central Manager
    private let centralManager: RxCentralManagerType

    // Queue on which all stream are serialized
    private let subscriptionQueue: SerializedSubscriptionQueue

    /// Internal structures lock
    private let lock = NSLock()

    // TODO: To be completed: seealso: scanForPeripherals
    /// Queue of scan operations to be completed
    private var scanQueue: [ScanOperation] = []

    private let disposeBag = DisposeBag()

    //MARK: Public interfaces

    /**
     Create new Bluetooth Manager with specified implemention of Bluetooth Central Manager which will execute operations
     by default on main thread.

     - Parameter centralManager: implementation of Central Manager
     - Parameter queueScheduler: scheduler on which serialized work will be executed
     */
    public init(centralManager: RxCentralManagerType,
                queueScheduler: SchedulerType = ConcurrentMainScheduler.instance) {
        self.centralManager = centralManager
        self.subscriptionQueue = SerializedSubscriptionQueue(scheduler: queueScheduler)
    }

    /**
     Create new Bluetooth Manager with default implmentation of Core Bluetooth Central Manager which callbacks are
     handled on main thread.
     */
    convenience public init() {
        self.init(centralManager: RxCBCentralManager(queue: dispatch_get_main_queue()))
    }

   /**
     Starts BLE scan for peripherals with given service UUIDs. When scan with the same set of UUIDs is
     in progress you will bind to it. Otherwise new scan will be queued.

     - parameter serviceUUIDs: Services of peripherals to search for. Nil value will accept all peripherals.
     - parameter options: Optional scanning options
     - returns: Stream of scanned peripherals.
    */
    public func scanForPeripherals(serviceUUIDs: [CBUUID]?, options: [String:AnyObject]? = nil)
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

                let operationBox = MutableBox<Observable<ScannedPeripheral>>()

                // Create new scan which will be processed in a queue
                let operation = Observable.create { (element: AnyObserver<ScannedPeripheral>) -> Disposable in

                    let operation = ScanOperation(UUIDs: serviceUUIDs, observable: operationBox.value!)
                    do { self.lock.lock(); defer { self.lock.unlock() }
                        self.scanQueue.append(operation)
                    }

                    // Start scanning for devices
                    self.centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: options)

                    // Observable which will emit next element, when peripheral is discovered.
                    self.centralManager.rx_didDiscoverPeripheral
                    .map { (peripheral, advertisment, rssi) -> ScannedPeripheral in
                        let peripheral = Peripheral(manager: self, peripheral: peripheral)
                        let advertismentData = AdvertisementData(advertisementData: advertisment)
                        return ScannedPeripheral(peripheral: peripheral,
                                          advertisementData: advertismentData, RSSI: rssi)
                    }
                    .subscribe(element)

                    return AnonymousDisposable {
                        //When disposed, stop all scans, and remove scanning operation from queue
                        self.centralManager.stopScan()
                        do { self.lock.lock(); defer { self.lock.unlock() }
                            if let index = self.scanQueue.indexOf({ $0 == operation }) {
                                self.scanQueue.removeAtIndex(index)
                            }
                        }
                    }

                }
                .queueSubscribeOn(self.subscriptionQueue)
                .publish()
                .refCount()

                operationBox.value = operation
                return operation
            }()
            // Allow scanning as long as bluetooth is powered on
            return self.ensureState(.PoweredOn, observable: observable)
        }
    }

    /**
     Returns current state of BLE Central Manager.

     - Returns: Current state of BLE Central Manager.
     */
    public var state: CBCentralManagerState {
        return centralManager.state
    }

    /**
     Starts observing state changes for BLE. It starts emitting current state first.

     - Returns: Stream of BLE states
     */
    public func monitorState() -> Observable<CBCentralManagerState> {
        return centralManager.rx_didUpdateState.startWith(centralManager.state)
    }

    // TODO: Consider adding monitorStateChange() without emitting current state. @maciek

    /**
     Establishes connection with BLE Peripheral

     - parameter peripheral: Peripheral to connect to
     - parameter options: Connection options
     - returns: Observation which emits next event after connection is established
     */
    public func connectToPeripheral(peripheral: Peripheral, options: [String:AnyObject]? = nil)
        -> Observable<Peripheral> {
        //TODO: Is it possible to connect simultaneously to two devices. If not we should consider
        //      doing this call in serialized queue.
        let success = centralManager.rx_didConnectPeripheral
        .filter { $0 == peripheral.peripheral }
        .map { _ in return peripheral }

        let error = centralManager.rx_didFailToConnectPeripheral
        .filter { $0.0 == peripheral.peripheral }
        .flatMap { (peripheral, error) -> Observable<Peripheral> in
            Observable.error(BluetoothError.PeripheralConnectionFailed(
                Peripheral(manager: self, peripheral: peripheral), error))
        }
        //Defer any action to moment of subscription
        let observable = Observable<Peripheral>.deferred {
            if let error = BluetoothError.errorFromState(self.state) {
                return Observable.error(error)
            }
            guard !peripheral.isConnected else {
                return Observable.just(peripheral)
            }
            self.centralManager.connectPeripheral(peripheral.peripheral, options: options)
            return success.amb(error)
        }

        return ensureState(.PoweredOn, observable: observable)
    }

    /**
     Cancels an active or pending local connection to a peripheral.

     - parameter peripheral: The peripheral to which the central manager is either trying to
                             connect or has already connected.
     - returns: Observation which emits next event when peripheral canceled connection
     */
    public func cancelConnectionToPeripheral(peripheral: Peripheral) -> Observable<Peripheral> {
        let observable = Observable<Peripheral>.deferred {
            //TODO: What if not connected? leave it to the OS?
            self.centralManager.cancelPeripheralConnection(peripheral.peripheral)
            return self.monitorPeripheralDisconnection(peripheral)
        }
        return ensureState(.PoweredOn, observable: observable)
    }

    /**
     Returns observable list of the peripherals containing any of the specified services currently
     connected to the system

     - parameter serviceUUIDs: A list of service UUIDs
     - returns: Observation which emits retrieved peripherals. Emited peripherals has to be connected to the system and
                has to contain any of the services specified in the serviceUUIDs parameter.
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
    Returns observable list of known peripherals by their identifiers
    - Parameter identifiers: List of peripheral identifiers from which CBPeripheral objects can be retrieved
    - Returns: Observation which emits next when peripherals are retrieved
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

    ///MARK:  Internal functions

    /**
     Ensure that state is preserved. It there is other state present error will be merged into stream.

     - parameter state: Central Manager State which should be ensured
     - parameter observable: Observable into which potential errors should be merged
     - returns: New observable which merges errors with source observable.
     */
    func ensureState<T>(state: CBCentralManagerState, observable: Observable<T>) -> Observable<T> {
        let statesObservable = monitorState()
        .filter { $0 != state && BluetoothError.errorFromState($0) != nil }
        .map { state -> T in throw BluetoothError.errorFromState(state)! }
        return Observable.of(statesObservable, observable).merge()
    }

    /**
     This function injects emits errors when peripheral is in disconnected state.

     - Parameter peripheral: Peripheral for which errors should be emitted when disconnected
     - Returns: Stream of disconnection errors
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
     Observe peripheral disconnection event

     - Parameter peripheral: Peripheral which disconnection events should be observed
     - Returns: Observation which emits next events when peripheral was disconnected
    */
    func monitorPeripheralDisconnection(peripheral: Peripheral) -> Observable<Peripheral> {
        return centralManager
        .rx_didDisconnectPeripheral
        .filter { $0.0 == peripheral.peripheral }
        .flatMap { (_, error) -> Observable<Peripheral> in
            return Observable.just(peripheral)
        }
    }
}
