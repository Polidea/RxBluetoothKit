import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class ScanResultsViewModel: ScanResultsViewModelType {

    let bluetoothService: RxBluetoothKitService

    var scanningOutput: Observable<Result<ScannedPeripheral, Error>> {
        return bluetoothService.scanningOutput
    }

    var isScanning: Bool = false

    init(with bluetoothService: RxBluetoothKitService) {
        self.bluetoothService = bluetoothService
    }

    func scanAction() {
        if isScanning {
            bluetoothService.stopScanning()
        } else {
            bluetoothService.startScanning()
        }

        isScanning = !isScanning
    }
}
