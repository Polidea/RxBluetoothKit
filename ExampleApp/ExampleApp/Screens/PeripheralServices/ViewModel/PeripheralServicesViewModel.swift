import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    var servicesOutput: Observable<[Service]> {
        return RxBluetoothKitService.shared.servicesOutput
    }

    private let disposeBag: DisposeBag = DisposeBag()

    private let bluetoothService: RxBluetoothKitService = RxBluetoothKitService.shared

    func connect() {
        bluetoothService.discoverServices()
    }
}
