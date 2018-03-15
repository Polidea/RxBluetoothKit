import RxBluetoothKit
import RxSwift
import Foundation

protocol PeripheralServicesViewModelType {

    var servicesOutput: Observable<Service> { get }

    var displayedPeripheral: Peripheral { get }

    var bluetoothService: RxBluetoothKitService { get }

    var disconnectionOutput: Observable<RxBluetoothKitService.Disconnection> { get }

    var errorOutput: Observable<Error> { get }

    func connect()

    func disconnect()
}