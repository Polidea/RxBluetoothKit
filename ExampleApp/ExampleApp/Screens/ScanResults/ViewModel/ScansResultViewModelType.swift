import Foundation
import RxBluetoothKit
import RxSwift

protocol ScanResultsViewModelType {

    var scanningOutput: Observable<ScannedPeripheral> { get }

    var bluetoothService: RxBluetoothKitService { get }

    var isScanning: Bool { get set }

    func scanAction()

}
