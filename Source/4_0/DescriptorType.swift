import Foundation
import CoreBluetooth
import RxSwift

protocol DescriptorType {

    associatedtype C

    var uuid: CBUUID { get }

    var characteristic: C { get }

    var value: Any? { get }
}

extension DescriptorType {

    public func monitorWrite() -> Observable<Self> {
        return .empty()
//        return characteristic.service.peripheral.monitorWrite(for: self)
    }

    public func writeValue(_ data: Data) -> Observable<Self> {
        return .empty()
//        return characteristic.service.peripheral.writeValue(data, for: self)
    }

    public func monitorValueUpdate() -> Observable<Self> {
        return .empty()
//        return characteristic.service.peripheral.monitorValueUpdate(for: self)
    }

    public func readValue() -> Observable<Self> {
        return .empty()
//        return characteristic.service.peripheral.readValue(for: self)
    }
}
