import RxBluetoothKit
import RxSwift

class BluetoothProvider {

    var scannedPeripheral: Observable<ScannedPeripheral> {
        scannedPeripheralSubject.asObservable()
    }

    func startScanning() {
        let managerIsOn = manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }
            .compactMap { [weak self] _ in self?.manager }

        connection = managerIsOn
            .flatMap { $0.scanForPeripherals(withServices: nil) }
            .timeout(.seconds(7), scheduler: MainScheduler.instance)
            .subscribe(scannedPeripheralSubject.asObserver())
    }

    func disconnect() {
        connection?.dispose()
    }

    deinit {
        disconnect()
    }

    // MARK: - Private

    private let manager = CentralManager()
    private var connection: Disposable?
    private let scannedPeripheralSubject = PublishSubject<ScannedPeripheral>()

}
