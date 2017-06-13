import Foundation
import CoreBluetooth

public final class Service: ServiceType {

    typealias P = Peripheral
    typealias C = Characteristic
    
    public let cbService: CBService

    init(cbService: CBService) {
        self.cbService = cbService
    }

    var uuid: CBUUID {
        return cbService.uuid
    }

    var peripheral: Peripheral {
        return Peripheral(cbPeripheral: cbService.peripheral)
    }

    /// Service's characteristics
    var characteristics: [Characteristic]? {
        return cbService.characteristics?.map(Characteristic.init)
    }

    /// Service's included services
    var includedServices: [Service]? {
        return cbService.includedServices?.map(Service.init)
    }

    /// True if service is a primary service
    var isPrimary: Bool {
        return cbService.isPrimary
    }
}
