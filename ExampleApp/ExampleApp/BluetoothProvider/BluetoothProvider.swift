import RxBluetoothKit
import RxSwift

class BluetoothProvider {

    typealias ConnectedPeripheral = Peripheral

    func startScanning() -> Observable<ScannedPeripheral> {
        let managerIsOn = manager.observeStateWithInitialValue()
            .filter { $0 == .poweredOn }
            .compactMap { [weak self] _ in self?.manager }

        connection = managerIsOn
            .flatMap { $0.scanForPeripherals(withServices: nil) }
            .timeout(.seconds(7), scheduler: MainScheduler.instance)
            .subscribe(scannedPeripheralSubject.asObserver())

        return scannedPeripheralSubject.asObservable()
    }

    func connect(to peripheral: Peripheral) -> Observable<ConnectedPeripheral> {
        peripheral.establishConnection()
    }

    func discoveredServices(for peripheral: ConnectedPeripheral) -> Observable<[Service]> {
        peripheral.discoverServices(nil).asObservable()
    }

    func characteristics(for service: Service) -> Observable<[Characteristic]> {
        service.discoverCharacteristics(nil).asObservable()
    }

    func readValue(for characteristic: Characteristic) -> Observable<String> {
        return characteristic.readValue().asObservable()
            .map { $0.value.flatMap { String(data: $0, encoding: .utf8) } ?? "-" }
    }

    func shutDown() {
        connection?.dispose()
    }

    deinit {
        shutDown()
    }

    // MARK: - Private

    private let manager = CentralManager()
    private var connection: Disposable?
    private let scannedPeripheralSubject = PublishSubject<ScannedPeripheral>()

}
