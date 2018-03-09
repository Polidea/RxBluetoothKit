import Foundation
import RxBluetoothKit
import RxSwift

protocol ScanResultsViewModelType {

    var scanningOutput: Observable<ScannedPeripheral> { get }

    var isScanning: Bool { get set }

    var bluetoothService: RxBluetoothKitService { get }
    
    func scanAction()

}
