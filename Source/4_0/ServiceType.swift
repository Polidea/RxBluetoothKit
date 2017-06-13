import Foundation
import CoreBluetooth
import RxSwift

protocol ServiceType {
    associatedtype P: PeripheralType
    associatedtype C: CharacteristicType where Self.C.S == Self

    var uuid: CBUUID { get }

    var peripheral: P { get }

    /// Service's characteristics
    var characteristics: [C]? { get }

    /// Service's included services
    var includedServices: [Self]? { get }

    /// True if service is a primary service
    var isPrimary: Bool { get }
}

extension ServiceType {

    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?) -> Observable<[C]> {
        return .empty()
//        return peripheral.discoverCharacteristics(characteristicUUIDs, for: self)
    }

    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?) -> Observable<[Self]> {
        return .empty()
//        return peripheral.discoverIncludedServices(includedServiceUUIDs, for: self)
    }
}
