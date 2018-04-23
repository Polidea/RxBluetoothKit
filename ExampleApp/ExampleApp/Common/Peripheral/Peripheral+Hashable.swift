import Foundation
import RxBluetoothKit

extension Peripheral: Hashable {

    // DJB Hashing
    public var hashValue: Int {
        let scalarArray: [UInt32] = []
        return scalarArray.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}
