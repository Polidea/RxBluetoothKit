import Foundation
import RxBluetoothKit
import CoreBluetooth

extension Characteristic {

    func determineWriteType() -> CBCharacteristicWriteType? {
        let writeType =  self.properties.contains(.write) ? CBCharacteristicWriteType.withResponse :
                self.properties.contains(.writeWithoutResponse) ? CBCharacteristicWriteType.withResponse : nil

        return writeType
    }
}
