//
//  Service.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth
import RxSwift

/**
 Class which represents peripheral's service
 */
public class Service {
    let service: RxServiceType

    /// Peripheral to which this service belongs
    public let peripheral: Peripheral

    /// True if service is primary service
    public var isPrimary: Bool {
        return service.isPrimary
    }

    /// Service's UUID
    public var uuid: CBUUID {
        return service.uuid
    }

    /// Service's included services
    public var includedServices: [Service]? {
        return service.includedServices?.map {
            Service(peripheral: peripheral, service: $0)
        } ?? nil
    }

    /// Service's characteristics
    public var characteristics: [Characteristic]? {
        return service.characteristics?.map {
            Characteristic(characteristic: $0, service: self)
        } ?? nil
    }

    /**
     Create new service.
     - parameter peripheral: Peripheral to which this service belongs.
     - parameter service: Service implementation.
     */
    public init(peripheral: Peripheral, service: RxServiceType) {
        self.service = service
        self.peripheral = peripheral
    }

    /**
     Wrapper function which allows to discover characteristics form a service class.

     - parameter identifiers: Indentifiers of characteristics which should be discovered. Should be `nil` if
                              user wants to discover all characteristics for this service.
     - returns: Observable which emits array of discovered characteristics after subscription.
     */
    public func discoverCharacteristics(identifiers: [CBUUID]) -> Observable<[Characteristic]> {
        return peripheral.discoverCharacteristics(identifiers, service: self)
    }
}

extension Service: Equatable {
}

/**
 Compare if services are equal. They are if theirs uuids are the same.

 - parameter lhs: First service
 - parameter rhs: Second service
 - returns: True if services are the same.
 */
public func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.service == rhs.service
}
