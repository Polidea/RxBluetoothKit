import RxBluetoothKit
import RxSwift
import Foundation

protocol PeripheralServicesViewModelType {

    var servicesOutput: Observable<[Service]> { get }

    func connect()
}