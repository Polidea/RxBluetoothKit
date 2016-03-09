//
//  Service.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth
import RxSwift

public class Service {
    let service: RxServiceType
    public let peripheral: Peripheral

    public var isPrimary: Bool {
        return service.isPrimary
    }

    public var uuid: CBUUID {
        return service.uuid
    }

    public var includedServices: [Service]? {
        return service.includedServices?.map {
            Service(peripheral: peripheral, service: $0)
        } ?? nil
    }

    public var characteristics: [Characteristic]? {
        return service.characteristics?.map {
            Characteristic(characteristic: $0, service: self)
        } ?? nil
    }

    public init(peripheral: Peripheral, service: RxServiceType) {
        self.service = service
        self.peripheral = peripheral
    }

    public func discoverCharacteristics(identifiers: [CBUUID]) -> Observable<[Characteristic]> {
        return peripheral.discoverCharacteristics(identifiers, service: self)
    }
}

extension Service: Equatable {
}

public func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.service == rhs.service
}
