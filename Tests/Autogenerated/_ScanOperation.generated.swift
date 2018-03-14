import Foundation
import CoreBluetooth
@testable import RxBluetoothKit
import RxSwift

final class _ScanOperation {
    let uuids: [CBUUID]?
    let observable: Observable<_ScannedPeripheral>
    init(uuids: [CBUUID]?, observable: Observable<_ScannedPeripheral>) {
        self.uuids = uuids
        self.observable = observable
    }
}

extension _ScanOperation {
    func shouldAccept(_ newUUIDs: [CBUUID]?) -> Bool {
        guard let uuids = uuids else {
            return true
        }
        guard let newUUIDs = newUUIDs else {
            return false
        }
        return Set(uuids).isSuperset(of: Set(newUUIDs))
    }
}

func == (lhs: _ScanOperation, rhs: _ScanOperation) -> Bool {
    if lhs.uuids == nil {
        return rhs.uuids == nil
    }
    return rhs.uuids != nil && rhs.uuids! == lhs.uuids!
}
