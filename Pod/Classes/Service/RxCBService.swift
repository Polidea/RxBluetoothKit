//
//  RxCBService.swift
//  Pods
//
//  Created by Kacper Harasim on 24.02.2016.
//
//

import Foundation
import CoreBluetooth
import RxSwift

class RxCBService: RxServiceType {

    let service: CBService
    init(service: CBService) {
        self.service = service
    }

    var uuid: CBUUID {
        return service.UUID
    }
    var characteristics: [RxCharacteristicType]? {
        guard let chars = service.characteristics else {
            return nil
        }
        return chars.map {
            RxCBCharacteristic(characteristic: $0)
        }
    }
    var includedServices: [RxServiceType]? {
        guard let services = service.includedServices else {
            return nil
        }
        return services.map {
            RxCBService(service: $0)
        }
    }
    var isPrimary: Bool {
        return service.isPrimary
    }
}
