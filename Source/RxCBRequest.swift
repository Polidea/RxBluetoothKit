//
//  RxCBRequest.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

class RxCBRequest: RxRequestType {
    
    let request: CBATTRequest
    init(request: CBATTRequest) {
        self.request = request
        self.central = Central(central: RxCBCentral(central: request.central))
        
//        Service(peripheral: RxCBMutablePeripheral, service: <#T##RxServiceType#>)
//        self.characteristic = Characteristic(characteristic: RxCBCharacteristic(characteristic: request.characteristic), service: Service(peripheral: <#T##Peripheral#>, service: FakeService())
    }
    
    var central: Central
    
//    var characteristic: Characteristic
    
    var offset: Int {
        return request.offset
    }
    
    var value: NSData? {
        return request.value
    }
}