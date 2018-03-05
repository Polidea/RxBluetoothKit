import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

class ScanResultsViewModel: ScanResultsViewModelType {

    var scanningOutput: Observable<ScannedPeripheral> {
        return scanningSubject.asObservable()
    }

    var isScanning: Bool = false

    private let scanningSubject: PublishSubject<ScannedPeripheral> = PublishSubject()

    private var scanningDisposable: Disposable!

    private let centralManager: CentralManager = CentralManager(queue: .main)

    private let scheduler: ConcurrentDispatchQueueScheduler

    init() {
        let timerQueue = DispatchQueue(label: "com.polidea.rxbluetoothkit.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
    }

    func scanAction() {
        if !isScanning {
            startScanning()
        } else {
            stopScanning()
        }

        isScanning = !isScanning
    }

    private func stopScanning() {
        scanningDisposable.dispose()
    }

    private func startScanning() {
        scanningDisposable = centralManager.observeState()
                .startWith(centralManager.state)
                .filter {
                    $0 == .poweredOn
                }
                .timeout(4.0, scheduler: scheduler)
                .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    return self.centralManager.scanForPeripherals(withServices: nil)
                }.bind(to: scanningSubject)
    }
}
