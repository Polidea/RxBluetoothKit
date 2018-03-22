import Foundation
import RxBluetoothKit
import RxSwift

protocol ScanResultsViewModelType {

    var scanningOutput: Observable<Result<ScannedPeripheral, Error>> { get }

    var bluetoothService: RxBluetoothKitService { get }

    var isScanning: Bool { get set }

    func scanAction()

}
