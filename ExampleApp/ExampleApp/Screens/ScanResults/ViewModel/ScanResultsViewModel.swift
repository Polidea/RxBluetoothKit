import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class ScanResultsViewModel: ScanResultsViewModelType {

    let bluetoothService: RxBluetoothKitService

    var scanningOutput: Observable<ScannedPeripheral> {
        return bluetoothService.scanningOutput
    }

    var isScanning: Bool = false

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
