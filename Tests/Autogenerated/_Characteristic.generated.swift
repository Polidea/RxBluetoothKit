import Foundation
import RxSwift
import CoreBluetooth
@testable import RxBluetoothKit

// swiftlint:disable line_length

/// _Characteristic is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with [CBCharacteristicMock](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/)
class _Characteristic {
    /// Intance of CoreBluetooth characteristic class
    let characteristic: CBCharacteristicMock

    /// _Service which contains this characteristic
    let service: _Service

    /// Current value of characteristic. If value is not present - it's `nil`.
    var value: Data? {
        return characteristic.value
    }

    /// The Bluetooth UUID of the `_Characteristic` instance.
    var uuid: CBUUID {
        return characteristic.uuid
    }

    /// Flag which is set to true if characteristic is currently notifying
    var isNotifying: Bool {
        return characteristic.isNotifying
    }

    /// Properties of characteristic. For more info about this refer to [CBCharacteristicProperties](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/#//apple_ref/c/tdef/CBCharacteristicProperties)
    var properties: CBCharacteristicProperties {
        return characteristic.properties
    }

    /// Value of this property is an array of `_Descriptor` objects. They provide more detailed information about characteristics value.
    var descriptors: [_Descriptor]? {
        return characteristic.descriptors?.map { _Descriptor(descriptor: $0, characteristic: self) }
    }

    init(characteristic: CBCharacteristicMock, service: _Service) {
        self.characteristic = characteristic
        self.service = service
    }

    convenience init(characteristic: CBCharacteristicMock, peripheral: _Peripheral) {
        let service = _Service(peripheral: peripheral, service: characteristic.service)
        self.init(characteristic: characteristic, service: service)
    }

    /// Function that triggers descriptors discovery for characteristic.
    /// - returns: `Single` that emits `next` with array of `_Descriptor` instances, once they're discovered.
    func discoverDescriptors() -> Single<[_Descriptor]> {
        return service.peripheral.discoverDescriptors(for: self)
    }

    /// Function that allow to observe writes that happened for characteristic.
    /// - Returns: `Observable` that emits `next` with `_Characteristic` instance every time when write has happened.
    /// It's **infinite** stream, so `.complete` is never called.
    func observeWrite() -> Observable<_Characteristic> {
        return service.peripheral.observeWrite(for: self)
    }

    /// Function that allows to know the exact time, when isNotyfing value has changed on a characteristic.
    ///
    /// - returns: `Observable` emitting `_Characteristic` when isNoytfing value has changed.
    func observeNotifyValue() -> Observable<_Characteristic> {
        return service.peripheral.observeNotifyValue(for: self)
    }

    /// Function that triggers write of data to characteristic. Write is called after subscribtion to `Observable` is made.
    /// Behavior of this function strongly depends on [CBCharacteristicWriteType](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/#//apple_ref/swift/enum/c:@E@CBCharacteristicWriteType), so be sure to check this out before usage of the method.
    /// - parameter data: `Data` that'll be written to the `_Characteristic`
    /// - parameter type: Type of write operation. Possible values: `.withResponse`, `.withoutResponse`
    /// - returns: `Single` whose emission depends on `CBCharacteristicWriteType` passed to the function call.
    /// Behavior is following:
    ///
    /// - `withResponse` -  `Observable` emits `next` with `_Characteristic` instance write was confirmed without any errors.
    /// If any problem has happened, errors are emitted.
    /// - `withoutResponse` - `Observable` emits `next` with `_Characteristic` instance once write was called.
    /// Result of this call is not checked, so as a user you are not sure
    /// if everything completed successfully. Errors are not emitted
    func writeValue(_ data: Data, type: CBCharacteristicWriteType) -> Single<_Characteristic> {
        return service.peripheral.writeValue(data, for: self, type: type)
    }

    /// Function that allow to observe value updates for `_Characteristic` instance.
    /// - Returns: `Observable` that emits `Next` with `_Characteristic` instance every time when value has changed.
    /// It's **infinite** stream, so `.complete` is never called.
    func observeValueUpdate() -> Observable<_Characteristic> {
        return service.peripheral.observeValueUpdate(for: self)
    }

    /// Function that triggers read of current value of the `_Characteristic` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Returns: `Single` which emits `next` with given characteristic when value is ready to read.
    func readValue() -> Single<_Characteristic> {
        return service.peripheral.readValue(for: self)
    }

    /// Setup characteristic notification in order to receive callbacks when given characteristic has been changed.
    /// Returned observable will emit `_Characteristic` on every notification change.
    /// It is possible to setup more observables for the same characteristic and the lifecycle of the notification will be shared among them.
    ///
    /// Notification is automaticaly unregistered once this observable is unsubscribed
    ///
    /// - returns: `Observable` emitting `next` with `_Characteristic` when given characteristic has been changed.
    ///
    /// This is **infinite** stream of values.
    func observeValueUpdateAndSetNotification() -> Observable<_Characteristic> {
        return service.peripheral.observeValueUpdateAndSetNotification(for: self)
    }
}

extension _Characteristic: Equatable {}
extension _Characteristic: UUIDIdentifiable {}

/// Compare two characteristics. Characteristics are the same when their UUIDs are the same.
///
/// - parameter lhs: First characteristic to compare
/// - parameter rhs: Second characteristic to compare
/// - returns: True if both characteristics are the same.
func == (lhs: _Characteristic, rhs: _Characteristic) -> Bool {
    return lhs.characteristic == rhs.characteristic
}
