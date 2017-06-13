import Foundation
import CoreBluetooth

public final class Descriptor: DescriptorType {
    typealias C = Characteristic
    
    public let cbDescriptor: CBDescriptor

    public var uuid: CBUUID {
        return cbDescriptor.uuid
    }

    public var characteristic: Characteristic {
        return Characteristic(cbCharacteristic: cbDescriptor.characteristic)
    }

    public var value: Any? {
        return cbDescriptor.value
    }

    init(cbDescriptor: CBDescriptor) {
        self.cbDescriptor = cbDescriptor
    }
}
