import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    var servicesOutput: Observable<[Service]> {
        return bluetoothService.servicesOutput
    }

    let displayedPeripheral: Peripheral

    let bluetoothService: RxBluetoothKitService

    private let disposeBag: DisposeBag = DisposeBag()

    init(with bluetoothService: RxBluetoothKitService, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.displayedPeripheral = peripheral
    }

    func connect() {
        bluetoothService.discoverServices(for: displayedPeripheral)
    }
}
