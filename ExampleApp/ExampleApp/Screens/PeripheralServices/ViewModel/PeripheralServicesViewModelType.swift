import RxBluetoothKit
import RxSwift
import Foundation

protocol PeripheralServicesViewModelType {

    var servicesOutput: Observable<[Service]> { get }

    var displayedPeripheral: Peripheral { get }

    func connect()
}