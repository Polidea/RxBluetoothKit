import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class ScanResultsViewModel: ScanResultsViewModelType {

    var scanningOutput: Observable<ScannedPeripheral> {
        return bluetoothService.scanningOutput
    }

    var isScanning: Bool = false

    private let bluetoothService: RxBluetoothKitService = RxBluetoothKitService.shared

    func scanAction() {
        if !isScanning {
            bluetoothService.startScanning()
        } else {
            bluetoothService.stopScanning()
        }

        isScanning = !isScanning
    }
}
