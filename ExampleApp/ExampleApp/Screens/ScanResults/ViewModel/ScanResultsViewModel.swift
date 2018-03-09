import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class ScanResultsViewModel: ScanResultsViewModelType {

    var scanningOutput: Observable<ScannedPeripheral> {
        return bluetoothService.scanningOutput
    }

    var isScanning: Bool = false

    let bluetoothService: RxBluetoothKitService

    init(with bluetoothService: RxBluetoothKitService) {
        self.bluetoothService = bluetoothService
    }

    func scanAction() {
        if !isScanning {
            bluetoothService.startScanning()
        } else {
            bluetoothService.stopScanning()
        }

        isScanning = !isScanning
    }
}
