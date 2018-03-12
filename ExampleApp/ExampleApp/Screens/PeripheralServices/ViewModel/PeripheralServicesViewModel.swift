import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    let displayedPeripheral: Peripheral

    let bluetoothService: RxBluetoothKitService

    var servicesOutput: Observable<[Service]> {
        return bluetoothService.servicesOutput
    }

    var disconnectionOutput: Observable<RxBluetoothKitService.Disconnection> {
        return bluetoothService.disconnectionReasonOutput
    }

    var errorOutput: Observable<Error> {
        return bluetoothService.errorOutput
    }

    private let disposeBag: DisposeBag = DisposeBag()

    init(with bluetoothService: RxBluetoothKitService, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.displayedPeripheral = peripheral
    }

    func connect() {
        bluetoothService.discoverServices(for: displayedPeripheral)
    }
}
