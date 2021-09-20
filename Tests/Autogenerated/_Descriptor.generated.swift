import Foundation
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

/// _Descriptor is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with
/// [CBDescriptorMock](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBDescriptor_Class/)
/// Descriptors provide more information about a characteristic’s value.
class _Descriptor {

    /// Intance of CoreBluetooth descriptor class
    let descriptor: CBDescriptorMock

    /// _Characteristic to which this descriptor belongs.
    let characteristic: _Characteristic

    /// The Bluetooth UUID of the `_Descriptor` instance.
    var uuid: CBUUID {
        return descriptor.uuid
    }

    /// The value of the descriptor. It can be written and read through functions on `_Descriptor` instance.
    var value: Any? {
        return descriptor.value
    }

    init(descriptor: CBDescriptorMock, characteristic: _Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }

    convenience init?(descriptor: CBDescriptorMock, peripheral: _Peripheral) {

        guard let _characteristic = descriptor.characteristic, let _service = _characteristic.service else {
            return nil
        }

        let service = _Service(peripheral: peripheral, service: _service)
        let characteristic = _Characteristic(characteristic: _characteristic, service: service)
        self.init(descriptor: descriptor, characteristic: characteristic)
    }

    /// Function that allow to observe writes that happened for descriptor.
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
    func observeWrite() -> Observable<_Descriptor> {
        return characteristic.service.peripheral.observeWrite(for: self)
    }

    /// Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
    /// - Parameter data: `Data` that'll be written to `_Descriptor` instance
    /// - Returns: `Single` that emits `Next` with `_Descriptor` instance, once value is written successfully.
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
    func writeValue(_ data: Data) -> Single<_Descriptor> {
        return characteristic.service.peripheral.writeValue(data, for: self)
    }

    /// Function that allow to observe value updates for `_Descriptor` instance.
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
    func observeValueUpdate() -> Observable<_Descriptor> {
        return characteristic.service.peripheral.observeValueUpdate(for: self)
    }

    /// Function that triggers read of current value of the `_Descriptor` instance.
    /// Read is called after subscription to `Observable` is made.
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
    func readValue() -> Single<_Descriptor> {
        return characteristic.service.peripheral.readValue(for: self)
    }
}

extension _Descriptor: Equatable {}

/// Compare two descriptors. Descriptors are the same when their UUIDs are the same.
///
/// - parameter lhs: First descriptor to compare
/// - parameter rhs: Second descriptor to compare
/// - returns: True if both descriptor are the same.
func == (lhs: _Descriptor, rhs: _Descriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}
