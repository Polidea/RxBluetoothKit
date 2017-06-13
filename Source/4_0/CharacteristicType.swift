import Foundation
import CoreBluetooth
import RxSwift

protocol CharacteristicType {

    associatedtype S: ServiceType
    associatedtype D: DescriptorType where Self.D.C == Self

    /// Characteristic UUID
    var uuid: CBUUID { get }

    /// Current characteristic value
    var value: Data? { get }

    /// True if characteristic value changes are notified
    var isNotifying: Bool { get }

    /// Characteristic properties
    var properties: CBCharacteristicProperties { get }

    /// Characteristic descriptors
    var descriptors: [D]? { get }

    /// Characteristic service
    var service: S { get }
}

extension CharacteristicType {

    public func discoverDescriptors() -> Observable<[D]> {
        return .empty()
//        return self.service.peripheral.discoverDescriptors(for: self)
    }

    public func monitorWrite() -> Observable<Self> {
        return .empty()
//        return service.peripheral.monitorWrite(for: self)
    }

    public func writeValue(_ data: Data, type: CBCharacteristicWriteType) -> Observable<Self> {
        return .empty()
//        return service.peripheral.writeValue(data, for: self, type: type)
    }

    public func monitorValueUpdate() -> Observable<Self> {
        return .empty()
//        return service.peripheral.monitorValueUpdate(for: self)
    }

    public func readValue() -> Observable<Self> {
        return .empty()
//        return service.peripheral.readValue(for: self)
    }

    public func setNotifyValue(_ enabled: Bool) -> Observable<Self> {
        return .empty()
//        return service.peripheral.setNotifyValue(enabled, for: self)
    }

    public func setNotificationAndMonitorUpdates() -> Observable<Self> {
        return .empty()
//        return service.peripheral.setNotificationAndMonitorUpdates(for: self)
    }

}
