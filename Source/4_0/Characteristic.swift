import Foundation
import CoreBluetooth

public final class Characteristic: CharacteristicType {
    typealias S = Service
    typealias D = Descriptor
    
    public let cbCharacteristic: CBCharacteristic

    init(cbCharacteristic: CBCharacteristic) {
        self.cbCharacteristic = cbCharacteristic
    }

    public var uuid: CBUUID {
        return cbCharacteristic.uuid
    }

    /// Current characteristic value
    public var value: Data? {
        return cbCharacteristic.value
    }

    /// True if characteristic value changes are notified
    public var isNotifying: Bool {
        return cbCharacteristic.isNotifying
    }

    /// Characteristic properties
    public var properties: CBCharacteristicProperties {
        return cbCharacteristic.properties
    }

    /// Characteristic descriptors
    public var descriptors: [Descriptor]? {
        return cbCharacteristic.descriptors?.map(Descriptor.init)
    }

    /// Characteristic service
    public var service: Service {
        fatalError()
    }
}
