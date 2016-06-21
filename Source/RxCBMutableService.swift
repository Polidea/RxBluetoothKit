//
//  RxCBMutableService.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/20/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift

class RxCBMutableService: RxMutableServiceType {
    
    let service: CBMutableService
    init(service: CBMutableService) {
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
    var includedServices: [RxMutableServiceType]? {
        guard let services = service.includedServices else {
            return nil
        }
        return services
            .map { CBMutableService(type: $0.UUID, primary: $0.isPrimary) }
            .map(RxCBMutableService.init)
    }
    var isPrimary: Bool {
        return service.isPrimary
    }
    
}