//
//  ScanOperation.swift
//  Pods
//
//  Created by Przemysław Lenart on 26/02/16.
//
//

import Foundation
import CoreBluetooth
import RxSwift

struct ScanOperation {
    let UUIDs: [CBUUID]?
    let observable: Observable<ScannedPeripheral>
}

extension ScanOperation {
    func acceptUUIDs(uuids: [CBUUID]?) -> Bool {
        return UUIDs == nil || Set(UUIDs!).isSubsetOf(uuids ?? [])
    }
}

func == (lhs: ScanOperation, rhs: ScanOperation) -> Bool {
    if lhs.UUIDs == nil {
        return rhs.UUIDs == nil
    }
    return rhs.UUIDs != nil && rhs.UUIDs! == lhs.UUIDs!
}
