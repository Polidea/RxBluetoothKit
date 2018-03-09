import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    var servicesOutput: Observable<[Service]> {
        return RxBluetoothKitService.shared.servicesOutput
    }

    let displayedPeripheral: Peripheral

    private let disposeBag: DisposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService = RxBluetoothKitService.shared

    init(with peripheral: Peripheral) {
        self.displayedPeripheral = peripheral
    }

    func connect() {
        bluetoothService.discoverServices(for: displayedPeripheral)
    }
}
