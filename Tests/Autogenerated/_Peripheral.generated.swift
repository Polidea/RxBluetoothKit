import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

// swiftlint:disable line_length
// swiftlint:disable type_body_length

/// _Peripheral is a class implementing ReactiveX API which wraps all Core Bluetooth functions
/// allowing to talk to peripheral like discovering characteristics, services and all of the read/write calls.
class _Peripheral {

    /// Intance of _CentralManager which is used to the bluetooth communication
    unowned let manager: _CentralManager

    /// Implementation of peripheral
    let peripheral: CBPeripheralMock

    /// Object responsible for characteristic notification observing
    private let notificationManager: CharacteristicNotificationManagerMock

    let delegateWrapper: CBPeripheralDelegateWrapperMock

    private let remainingServicesDiscoveryRequest = ThreadSafeBox<Int>(value: 0)
    private let peripheralDidDiscoverServices = PublishSubject<([CBServiceMock]?, Error?)>()

    private let remainingIncludedServicesDiscoveryRequest = ThreadSafeBox<[CBUUID: Int]>(value: [CBUUID: Int]())
    private let peripheralDidDiscoverIncludedServicesForService = PublishSubject<(CBServiceMock, Error?)>()

    private let remainingCharacteristicsDiscoveryRequest = ThreadSafeBox<[CBUUID: Int]>(value: [CBUUID: Int]())
    private let peripheralDidDiscoverCharacteristicsForService = PublishSubject<(CBServiceMock, Error?)>()

    private let disposeBag = DisposeBag()

    /// Creates new `_Peripheral`
    /// - parameter manager: Central instance which is used to perform all of the necessary operations.
    /// - parameter peripheral: Instance representing specific peripheral allowing to perform operations on it.
    /// - parameter delegateWrapper: Rx wrapper for `CBPeripheralDelegate`.
    /// - parameter notificationManager: Instance used to observe characteristics notification
    init(
        manager: _CentralManager,
        peripheral: CBPeripheralMock,
        delegateWrapper: CBPeripheralDelegateWrapperMock,
        notificationManager: CharacteristicNotificationManagerMock
    ) {
        self.manager = manager
        self.peripheral = peripheral
        self.delegateWrapper = delegateWrapper
        self.notificationManager = notificationManager
        peripheral.delegate = self.delegateWrapper

        setupSubjects()
    }

    convenience init(manager: _CentralManager,
                     peripheral: CBPeripheralMock,
                     delegateWrapper: CBPeripheralDelegateWrapperMock) {
        let notificationManager = CharacteristicNotificationManagerMock(peripheral: peripheral, delegateWrapper: delegateWrapper)
        self.init(manager: manager,
                  peripheral: peripheral,
                  delegateWrapper: delegateWrapper,
                  notificationManager: notificationManager)
    }

    private func setupSubjects() {
        manager.delegateWrapper
            .didDisconnectPeripheral
            .filter { [weak self] peripheral, _ in
                peripheral.uuidIdentifier == self?.peripheral.uuidIdentifier
            }
            .subscribe(onNext: { [weak self] _ in
                self?.remainingServicesDiscoveryRequest.writeSync { value in
                    value = 0
                }

                self?.remainingIncludedServicesDiscoveryRequest.writeSync { array in
                    array.removeAll()
                }

                self?.remainingCharacteristicsDiscoveryRequest.writeSync { array in
                    array.removeAll()
                }
            })
            .disposed(by: disposeBag)

        delegateWrapper.peripheralDidDiscoverServices.subscribe { [weak self] event in
            self?.remainingServicesDiscoveryRequest.writeSync { value in
                if value > 0 {
                    value -= 1
                }
            }
            self?.peripheralDidDiscoverServices.on(event)
        }.disposed(by: disposeBag)

        delegateWrapper.peripheralDidDiscoverIncludedServicesForService.subscribe { [weak self] event in
            self?.remainingIncludedServicesDiscoveryRequest.writeSync { array in
                if let element = event.element {
                    let oldValue = array[element.0.uuid] ?? 1
                    if oldValue > 0 {
                        array[element.0.uuid] = oldValue - 1
                    }
                }
            }
            self?.peripheralDidDiscoverIncludedServicesForService.on(event)
        }.disposed(by: disposeBag)

        delegateWrapper.peripheralDidDiscoverCharacteristicsForService.subscribe { [weak self] event in
            self?.remainingCharacteristicsDiscoveryRequest.writeSync { array in
                if let element = event.element {
                    let oldValue = array[element.0.uuid] ?? 1
                    if oldValue > 0 {
                        array[element.0.uuid] = oldValue - 1
                    }
                }
            }
            self?.peripheralDidDiscoverCharacteristicsForService.on(event)
        }.disposed(by: disposeBag)
    }

    /// Attaches RxBluetoothKit delegate to CBPeripheralMock.
    /// This method is useful in cases when delegate of CBPeripheralMock was reassigned outside of
    /// RxBluetoothKit library (e.g. CBPeripheralMock was used in some other library or used in non-reactive way)
    func attach() {
        peripheral.delegate = delegateWrapper
    }

    /// Value indicating if peripheral is currently in connected state.
    var isConnected: Bool {
        return peripheral.state == .connected
    }

    ///  Current state of `_Peripheral` instance described by [CBPeripheralState](https://developer.apple.com/documentation/corebluetooth/cbperipheralstate).
    ///  - returns: Current state of `_Peripheral` as `CBPeripheralState`.
    var state: CBPeripheralState {
        return peripheral.state
    }

    /// Current name of `_Peripheral` instance. Analogous to [name](https://developer.apple.com/documentation/corebluetooth/cbperipheral/1519029-name) of `CBPeripheralMock`.
    var name: String? {
        return peripheral.name
    }

    /// Unique identifier of `_Peripheral` instance. Assigned once peripheral is discovered by the system.
    var identifier: UUID {
        return peripheral.uuidIdentifier
    }

    /// A list of services that have been discovered. Analogous to [services](https://developer.apple.com/documentation/corebluetooth/cbperipheral/1518978-services) of `CBPeripheralMock`.
    var services: [_Service]? {
        return peripheral.services?.map {
            _Service(peripheral: self, service: $0)
        }
    }

    /// YES if the remote device has space to send a write without response. If this value is NO,
    /// the value will be set to YES after the current writes have been flushed, and
    /// `peripheralIsReadyToSendWriteWithoutResponse:` will be called.
    var canSendWriteWithoutResponse: Bool {
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            return peripheral.canSendWriteWithoutResponse
        } else {
            return true
        }
    }

    // MARK: Connecting

    ///  Continuous value indicating if peripheral is in connected state. This is continuous value, which emits `.next` whenever state change occurs
    /// - returns Observable which emits next events when `_Peripheral` is connected or disconnected.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeConnection() -> Observable<Bool> {
        let disconnected = manager.observeDisconnect(for: self).map { _ in false }
        let connected = manager.observeConnect(for: self).map { _ in true }
        return Observable.of(disconnected, connected).merge()
    }

    /// Establishes connection with a given `_Peripheral`.
    /// For more information look into `_CentralManager.establishConnection(with:options:)` because this method calls it directly.
    /// - parameter options: Dictionary to customise the behaviour of connection.
    /// - returns: `Observable` which emits `next` event after connection is established.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.peripheralIsAlreadyObservingConnection`
    /// * `_BluetoothError.peripheralConnectionFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func establishConnection(options: [String: Any]? = nil) -> Observable<_Peripheral> {
        return manager.establishConnection(self, options: options)
    }

    // MARK: Services

    /// Triggers discover of specified services of peripheral. If the servicesUUIDs parameter is nil, all the available services of the
    /// peripheral are returned; setting the parameter to nil is considerably slower and is not recommended.
    /// If all of the specified services are already discovered - these are returned without doing any underlying Bluetooth operations.
    ///
    /// - Parameter serviceUUIDs: An array of [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/)
    /// objects that you are interested in. Here, each [CBUUID](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBUUID_Class/)
    /// object represents a UUID that identifies the type of service you want to discover.
    /// - Returns: `Single` that emits `next` with array of `_Service` instances, once they're discovered.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.servicesDiscoveryFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func discoverServices(_ serviceUUIDs: [CBUUID]?) -> Single<[_Service]> {
        if let identifiers = serviceUUIDs, !identifiers.isEmpty,
            let cachedServices = self.services,
            let filteredServices = filterUUIDItems(uuids: serviceUUIDs, items: cachedServices, requireAll: true) {
            return ensureValidPeripheralState(for: .just(filteredServices)).asSingle()
        }
        let observable = peripheralDidDiscoverServices
            .filter { [weak self] (services, error) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                guard let cachedServices = strongSelf.services, error == nil else { return true }
                let foundRequestedServices = serviceUUIDs != nil && filterUUIDItems(uuids: serviceUUIDs, items: cachedServices, requireAll: true) != nil
                return foundRequestedServices || strongSelf.remainingServicesDiscoveryRequest.read { $0 == 0 }
            }
            .flatMap { [weak self] (_, error) -> Observable<[_Service]> in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                guard let cachedServices = strongSelf.services, error == nil else {
                    throw _BluetoothError.servicesDiscoveryFailed(strongSelf, error)
                }
                if let filteredServices = filterUUIDItems(uuids: serviceUUIDs, items: cachedServices, requireAll: false) {
                    return .just(filteredServices)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.remainingServicesDiscoveryRequest.writeSync { value in
                    value += 1
                }
                self?.peripheral.discoverServices(serviceUUIDs)
            }
        )
        .asSingle()
    }

    /// Function that triggers included services discovery for specified services. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// If all of the specified included services are already discovered - these are returned without doing any underlying Bluetooth
    /// operations.
    ///
    /// - Parameter includedServiceUUIDs: Identifiers of included services that should be discovered. If `nil` - all of the
    /// included services will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Parameter service: _Service of which included services should be discovered.
    /// - Returns: `Single` that emits `next` with array of `_Service` instances, once they're discovered.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.includedServicesDiscoveryFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: _Service) -> Single<[_Service]> {
        if let identifiers = includedServiceUUIDs, !identifiers.isEmpty,
            let services = service.includedServices,
            let filteredServices = filterUUIDItems(uuids: includedServiceUUIDs, items: services, requireAll: true) {
            return ensureValidPeripheralState(for: .just(filteredServices)).asSingle()
        }
        let observable = peripheralDidDiscoverIncludedServicesForService
            .filter { $0.0 == service.service }
            .filter { [weak self] (cbService, error) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                guard let includedCBServices = cbService.includedServices, error == nil else { return true }

                let includedServices = includedCBServices.map { _Service(peripheral: strongSelf, service: $0) }
                let foundRequestedServices = includedServiceUUIDs != nil && filterUUIDItems(uuids: includedServiceUUIDs, items: includedServices, requireAll: true) != nil
                return foundRequestedServices || strongSelf.remainingIncludedServicesDiscoveryRequest.read { array in
                    return (array[cbService.uuid] ?? 0) == 0
                }
            }
            .flatMap { [weak self] (cbService, error) -> Observable<[_Service]> in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                guard let includedRxServices = cbService.includedServices, error == nil else {
                    throw _BluetoothError.includedServicesDiscoveryFailed(strongSelf, error)
                }
                let includedServices = includedRxServices.map { _Service(peripheral: strongSelf, service: $0) }
                if let filteredServices = filterUUIDItems(uuids: includedServiceUUIDs, items: includedServices, requireAll: false) {
                    return .just(filteredServices)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.remainingIncludedServicesDiscoveryRequest.writeSync { array in
                    let oldValue = array[service.uuid] ?? 0
                    array[service.uuid] = oldValue + 1
                }
                self?.peripheral.discoverIncludedServices(includedServiceUUIDs, for: service.service)
            }
        )
        .asSingle()
    }

    // MARK: Characteristics

    /// Function that triggers characteristics discovery for specified Services and identifiers. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// If all of the specified characteristics are already discovered - these are returned without doing any underlying Bluetooth operations.
    ///
    /// - Parameter characteristicUUIDs: Identifiers of characteristics that should be discovered. If `nil` - all of the
    /// characteristics will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Parameter service: _Service of which characteristics should be discovered.
    /// - Returns: `Single` that emits `next` with array of `_Characteristic` instances, once they're discovered.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicsDiscoveryFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: _Service) -> Single<[_Characteristic]> {
        if let identifiers = characteristicUUIDs, !identifiers.isEmpty,
            let characteristics = service.characteristics,
            let filteredCharacteristics = filterUUIDItems(uuids: characteristicUUIDs, items: characteristics, requireAll: true) {
            return ensureValidPeripheralState(for: .just(filteredCharacteristics)).asSingle()
        }
        let observable = peripheralDidDiscoverCharacteristicsForService
            .filter { $0.0 == service.service }
            .filter { [weak self] (cbService, error) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                guard let cbCharacteristics = cbService.characteristics, error == nil else { return true }

                let characteristics = cbCharacteristics.map { _Characteristic(characteristic: $0, service: service) }
                let foundRequestedCharacteristis = characteristicUUIDs != nil && filterUUIDItems(uuids: characteristicUUIDs, items: characteristics, requireAll: true) != nil
                return foundRequestedCharacteristis || strongSelf.remainingCharacteristicsDiscoveryRequest.read { array in
                    return (array[cbService.uuid] ?? 0) == 0
                }
            }
            .flatMap { (cbService, error) -> Observable<[_Characteristic]> in
                guard let cbCharacteristics = cbService.characteristics, error == nil else {
                    throw _BluetoothError.characteristicsDiscoveryFailed(service, error)
                }
                let characteristics = cbCharacteristics.map { _Characteristic(characteristic: $0, service: service) }
                if let filteredCharacteristics = filterUUIDItems(uuids: characteristicUUIDs, items: characteristics, requireAll: false) {
                    return .just(filteredCharacteristics)
                }
                return .empty()
            }
            .take(1)

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.remainingCharacteristicsDiscoveryRequest.writeSync { array in
                    let oldValue = array[service.uuid] ?? 0
                    array[service.uuid] = oldValue + 1
                }
                self?.peripheral.discoverCharacteristics(characteristicUUIDs, for: service.service)
            }
        ).asSingle()
    }

    /// Function that allow to observe writes that happened for characteristic.
    /// - Parameter characteristic: Optional `_Characteristic` of which value changes should be observed. When not specified it will observe for any `_Characteristic`.
    /// - Returns: Observable that emits `next` with `_Characteristic` instance every time when write has happened.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicWriteFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeWrite(for characteristic: _Characteristic? = nil) -> Observable<_Characteristic> {
        let observable = delegateWrapper
            .peripheralDidWriteValueForCharacteristic
            .filter { characteristic != nil ? ($0.0 == characteristic!.characteristic) : true }
            .map { [weak self] (cbCharacteristic, error) -> _Characteristic in
                guard let strongSelf = self,
                      let characteristic = characteristic ?? _Characteristic(characteristic: cbCharacteristic, peripheral: strongSelf) else { throw _BluetoothError.destroyed }

                if let error = error {
                    throw _BluetoothError.characteristicWriteFailed(characteristic, error)
                }
                return characteristic
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// The maximum amount of data, in bytes, that can be sent to a characteristic in a single write.
    /// - parameter type: Type of write operation. Possible values: `.withResponse`, `.withoutResponse`
    /// - seealso: `writeValue(_:for:type:)`
    @available(OSX 10.12, iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }

    /// Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
    /// Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/documentation/corebluetooth/cbcharacteristicwritetype),
    /// so be sure to check this out before usage of the method.
    ///
    /// Behavior is following:
    /// - `withResponse` -  Observable emits `next` with `_Characteristic` instance write was confirmed without any errors.
    /// Immediately after that `complete` is called. If any problem has happened, errors are emitted.
    /// - `withoutResponse` - Observable emits `next` with `_Characteristic` instance once write was called.
    /// Immediately after that `.complete` is called. Result of this call is not checked, so as a user you are not sure
    /// if everything completed successfully. Errors are not emitted. It ensures that peripheral is ready to write
    /// without response by listening to the proper delegate method
    ///
    /// - parameter data: Data that'll be written to `_Characteristic` instance
    /// - parameter characteristic: `_Characteristic` instance to write value to.
    /// - parameter type: Type of write operation. Possible values: `.withResponse`, `.withoutResponse`
    /// - parameter canSendWriteWithoutResponseCheckEnabled: check if canSendWriteWithoutResponse should be enabled. Done because of internal MacOS bug.
    /// - returns: Observable that emission depends on `CBCharacteristicWriteType` passed to the function call.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicWriteFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func writeValue(_ data: Data,
                           for characteristic: _Characteristic,
                           type: CBCharacteristicWriteType,
                           canSendWriteWithoutResponseCheckEnabled: Bool = true) -> Single<_Characteristic> {
        let writeOperationPerformingAndListeningObservable = { [weak self] (observable: Observable<_Characteristic>)
            -> Observable<_Characteristic> in
            guard let strongSelf = self else { return Observable.error(_BluetoothError.destroyed) }
            return strongSelf.ensureValidPeripheralStateAndCallIfSucceeded(
                for: observable,
                postSubscriptionCall: { [weak self] in
                    self?.peripheral.writeValue(data, for: characteristic.characteristic, type: type)
                }
            )
        }
        switch type {
        case .withoutResponse:
            return observeWriteWithoutResponseReadiness()
                .map { _ in true }
                .startWith(canSendWriteWithoutResponseCheckEnabled ? canSendWriteWithoutResponse : true)
                .filter { $0 }
                .take(1)
                .flatMap { _ in
                    writeOperationPerformingAndListeningObservable(Observable.just(characteristic))
                }.asSingle()
        case .withResponse:
            return writeOperationPerformingAndListeningObservable(observeWrite(for: characteristic).take(1))
                .asSingle()
        @unknown default:
            return .error(_BluetoothError.unknownWriteType)
        }
    }

    /// Function that allow to observe value updates for `_Characteristic` instance.
    /// - Parameter characteristic: Optional `_Characteristic` of which value changes should be observed. When not specified it will observe for any `_Characteristic`.
    /// - Returns: Observable that emits `next` with `_Characteristic` instance every time when value has changed.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicReadFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeValueUpdate(for characteristic: _Characteristic? = nil) -> Observable<_Characteristic> {
        let observable = delegateWrapper
            .peripheralDidUpdateValueForCharacteristic
            .filter { characteristic != nil ? ($0.0 == characteristic!.characteristic) : true }
            .map { [weak self] (cbCharacteristic, error) -> _Characteristic in
                guard let strongSelf = self, let characteristic = characteristic ?? _Characteristic(characteristic: cbCharacteristic, peripheral: strongSelf) else { throw _BluetoothError.destroyed }

                if let error = error {
                    throw _BluetoothError.characteristicReadFailed(characteristic, error)
                }
                return characteristic
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that triggers read of current value of the `_Characteristic` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Parameter characteristic: `_Characteristic` to read value from
    /// - Returns: `Single` which emits `next` with given characteristic when value is ready to read.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicReadFailed`
    func readValue(for characteristic: _Characteristic) -> Single<_Characteristic> {
        let observable = observeValueUpdate(for: characteristic).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.readValue(for: characteristic.characteristic)
            }
        ).asSingle()
    }

    /// Setup characteristic notification in order to receive callbacks when given characteristic has been changed.
    /// Returned observable will emit `_Characteristic` on every notification change.
    /// It is possible to setup more observables for the same characteristic and the lifecycle of the notification will be shared among them.
    ///
    /// Notification is automaticaly unregistered once this observable is unsubscribed
    ///
    /// - parameter characteristic: `_Characteristic` for notification setup.
    /// - returns: `Observable` emitting `_Characteristic` when given characteristic has been changed.
    ///
    /// This is **infinite** stream of values.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicReadFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeValueUpdateAndSetNotification(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        let observable = notificationManager.observeValueUpdateAndSetNotification(for: characteristic)
        return ensureValidPeripheralState(for: observable)
    }

    /// Use this function in order to know the exact time, when isNotyfing value has changed on a _Characteristic.
    ///
    /// - parameter characteristic: `_Characteristic` which you observe for isNotyfing changes.
    /// - returns: `Observable` emitting `_Characteristic` when given characteristic has changed it's isNoytfing value.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.characteristicSetNotifyValueFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeNotifyValue(for characteristic: _Characteristic) -> Observable<_Characteristic> {
        return delegateWrapper.peripheralDidUpdateNotificationStateForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .map { [weak self] (cbCharacteristic, error) -> _Characteristic in
                guard let strongSelf = self,
                      let characteristic = _Characteristic(characteristic: cbCharacteristic, peripheral: strongSelf) else { throw _BluetoothError.destroyed }

                if let error = error {
                    throw _BluetoothError.characteristicSetNotifyValueFailed(characteristic, error)
                }
                return characteristic
        }
    }

    // MARK: Descriptors

    /// Function that triggers descriptors discovery for characteristic
    /// If all of the descriptors are already discovered - these are returned without doing any underlying Bluetooth operations.
    /// - Parameter characteristic: `_Characteristic` instance for which descriptors should be discovered.
    /// - Returns: `Single` that emits `next` with array of `_Descriptor` instances, once they're discovered.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.descriptorsDiscoveryFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func discoverDescriptors(for characteristic: _Characteristic) -> Single<[_Descriptor]> {
        if let descriptors = characteristic.descriptors {
            let resultDescriptors = descriptors.map { _Descriptor(descriptor: $0.descriptor, characteristic: characteristic) }
            return ensureValidPeripheralState(for: .just(resultDescriptors)).asSingle()
        }
        let observable = delegateWrapper
            .peripheralDidDiscoverDescriptorsForCharacteristic
            .filter { $0.0 == characteristic.characteristic }
            .take(1)
            .map { (cbCharacteristic, error) -> [_Descriptor] in
                if let descriptors = cbCharacteristic.descriptors, error == nil {
                    return descriptors.map {
                        _Descriptor(descriptor: $0, characteristic: characteristic) }
                }
                throw _BluetoothError.descriptorsDiscoveryFailed(characteristic, error)
            }

        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.discoverDescriptors(for: characteristic.characteristic)
            }
        ).asSingle()
    }

    /// Function that allow to observe writes that happened for descriptor.
    /// - Parameter descriptor: Optional `_Descriptor` of which value changes should be observed. When not specified it will observe for any `_Descriptor`.
    /// - Returns: Observable that emits `next` with `_Descriptor` instance every time when write has happened.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.descriptorWriteFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeWrite(for descriptor: _Descriptor? = nil) -> Observable<_Descriptor> {
        let observable = delegateWrapper
            .peripheralDidWriteValueForDescriptor
            .filter { descriptor != nil ? ($0.0 == descriptor!.descriptor) : true }
            .map { [weak self] (cbDescriptor, error) -> _Descriptor in
                guard let strongSelf = self, let descriptor = descriptor ?? _Descriptor(descriptor: cbDescriptor, peripheral: strongSelf) else { throw _BluetoothError.destroyed }

                if let error = error {
                    throw _BluetoothError.descriptorWriteFailed(descriptor, error)
                }
                return descriptor
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that allow to observe value updates for `_Descriptor` instance.
    /// - Parameter descriptor: Optional `_Descriptor` of which value changes should be observed. When not specified it will observe for any `_Descriptor`.
    /// - Returns: Observable that emits `next` with `_Descriptor` instance every time when value has changed.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.descriptorReadFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeValueUpdate(for descriptor: _Descriptor? = nil) -> Observable<_Descriptor> {
        let observable = delegateWrapper
            .peripheralDidUpdateValueForDescriptor
            .filter { descriptor != nil ? ($0.0 == descriptor!.descriptor) : true }
            .map { [weak self] (cbDescriptor, error) -> _Descriptor in
                guard let strongSelf = self, let descriptor = descriptor ?? _Descriptor(descriptor: cbDescriptor, peripheral: strongSelf) else { throw _BluetoothError.destroyed }
                if let error = error {
                    throw _BluetoothError.descriptorReadFailed(descriptor, error)
                }
                return descriptor
            }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that triggers read of current value of the `_Descriptor` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Parameter descriptor: `_Descriptor` to read value from
    /// - Returns: `Single` which emits `next` with given descriptor when value is ready to read.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.descriptorReadFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func readValue(for descriptor: _Descriptor) -> Single<_Descriptor> {
        let observable = observeValueUpdate(for: descriptor).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observable,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.readValue(for: descriptor.descriptor) }
        )
        .asSingle()
    }

    /// Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
    /// - Parameter data: `Data` that'll be written to `_Descriptor` instance
    /// - Parameter descriptor: `_Descriptor` instance to write value to.
    /// - Returns: `Single` that emits `next` with `_Descriptor` instance, once value is written successfully.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.descriptorWriteFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func writeValue(_ data: Data, for descriptor: _Descriptor) -> Single<_Descriptor> {
        let observeWrite = self.observeWrite(for: descriptor).take(1)
        return ensureValidPeripheralStateAndCallIfSucceeded(
            for: observeWrite,
            postSubscriptionCall: { [weak self] in
                self?.peripheral.writeValue(data, for: descriptor.descriptor) }
        )
        .asSingle()
    }

    // MARK: Other methods

    /// Function that triggers read of `_Peripheral` RSSI value. Read is called after subscription to `Observable` is made.
    /// - returns: `Single` that emits tuple: `(_Peripheral, Int)` once new RSSI value is read.
    /// `Int` is new RSSI value, `_Peripheral` is returned to allow easier chaining.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.peripheralRSSIReadFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func readRSSI() -> Single<(_Peripheral, Int)> {
        let observable = delegateWrapper
            .peripheralDidReadRSSI
            .take(1)
            .map { [weak self] (rssi, error) -> (_Peripheral, Int) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                if let error = error {
                    throw _BluetoothError.peripheralRSSIReadFailed(strongSelf, error)
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

    /// Function that allow user to observe incoming `name` property changes of `_Peripheral` instance.
    /// - returns: `Observable` that emits tuples: `(_Peripheral, String?)` when name has changed.
    ///    It's `optional String` because peripheral could also lost his name.
    ///    It's **infinite** stream of values, so `.complete` is never emitted.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeNameUpdate() -> Observable<(_Peripheral, String?)> {
        let observable = delegateWrapper.peripheralDidUpdateName.map { [weak self] name -> (_Peripheral, String?) in
            guard let strongSelf = self else { throw _BluetoothError.destroyed }
            return (strongSelf, name)
        }
        return ensureValidPeripheralState(for: observable)
    }

    /// Function that allow to observe incoming service modifications for `_Peripheral` instance.
    /// In case you're interested what exact changes might occur - please refer to
    /// [Apple Documentation](https://developer.apple.com/documentation/corebluetooth/cbperipheraldelegate/1518865-peripheral)
    ///
    /// - returns: `Observable` that emits tuples: `(_Peripheral, [_Service])` when services were modified.
    ///    It's **infinite** stream of values, so `.complete` is never emitted.
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    func observeServicesModification() -> Observable<(_Peripheral, [_Service])> {
        let observable = delegateWrapper.peripheralDidModifyServices
            .map { [weak self] services -> [_Service] in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                return services.map { _Service(peripheral: strongSelf, service: $0) } }
            .map { [weak self] services -> (_Peripheral, [_Service]) in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                return (strongSelf, services)
        }
        return ensureValidPeripheralState(for: observable)
    }

    /// Resulting observable emits next element if call to `writeValue:forCharacteristic:type:` has failed,
    /// to indicate when peripheral is again ready to send characteristic value updates again.
    func observeWriteWithoutResponseReadiness() -> Observable<Void> {
        return delegateWrapper.peripheralIsReadyToSendWriteWithoutResponse.asObservable()
    }

    /// Function that allow to open L2CAP channel for `_Peripheral` instance.
    /// For more information, please refer to
    /// [What’s New in CoreBluetooth, 712, WWDC 2017](https://developer.apple.com/videos/play/wwdc2017/712/)
    ///
    /// - parameter PSM: `PSM` (Protocol/_Service Multiplexer) of the channel
    /// - returns: `Single` that emits `CBL2CAPChannelMock` when channel has opened
    /// - since: iOS 11, tvOS 11, watchOS 4
    ///
    /// Observable can ends with following errors:
    /// * `_BluetoothError.openingL2CAPChannelFailed`
    /// * `_BluetoothError.peripheralDisconnected`
    /// * `_BluetoothError.destroyed`
    /// * `_BluetoothError.bluetoothUnsupported`
    /// * `_BluetoothError.bluetoothUnauthorized`
    /// * `_BluetoothError.bluetoothPoweredOff`
    /// * `_BluetoothError.bluetoothInUnknownState`
    /// * `_BluetoothError.bluetoothResetting`
    @available(iOS 11, macOS 10.14, tvOS 11, watchOS 4, *)
    func openL2CAPChannel(PSM: CBL2CAPPSM) -> Single<CBL2CAPChannelMock> {
        let observable = delegateWrapper
            .peripheralDidOpenL2CAPChannel
            .map {($0.0 as? CBL2CAPChannelMock, $0.1)}
            .take(1)
            .flatMap { [weak self] (channel, error) -> Observable<CBL2CAPChannelMock> in
                guard let strongSelf = self else { throw _BluetoothError.destroyed }
                if let channel = channel, error == nil {
                    return .just(channel)
                } else {
                    throw _BluetoothError.openingL2CAPChannelFailed(strongSelf, error)
                }
        }

        return ensureValidPeripheralStateAndCallIfSucceeded(for: observable, postSubscriptionCall: { [weak self] in
            self?.peripheral.openL2CAPChannel(PSM)
        }).asSingle()
    }

    // MARK: Internal functions

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
    /// - returns: Source `Observable` which listens on state change errors as well
    func ensureValidPeripheralState<T>(for observable: Observable<T>) -> Observable<T> {
        return Observable<T>.absorb(
            manager.ensurePeripheralIsConnected(self),
            manager.ensure(.poweredOn, observable: observable)
        )
    }
}

extension _Peripheral: Equatable {}

/// Compare two peripherals which are the same when theirs identifiers are equal.
///
/// - parameter lhs: First peripheral to compare
/// - parameter rhs: Second peripheral to compare
/// - returns: True if both peripherals are the same
func == (lhs: _Peripheral, rhs: _Peripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
}
