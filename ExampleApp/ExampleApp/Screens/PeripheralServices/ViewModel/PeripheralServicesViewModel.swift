import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    private let disposeBag: DisposeBag = DisposeBag()
    private let bluetoothService: RxBluetoothKitService = RxBluetoothKitService.shared

    func connect() {
        bluetoothService.connectToPeripheral()
    }
}
