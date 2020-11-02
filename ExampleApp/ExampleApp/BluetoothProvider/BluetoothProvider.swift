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
        characteristic.readValue().asObservable()
            .map { $0.stringValue }
    }

    func getValueUpdates(for characteristic: Characteristic) -> Observable<String> {
        characteristic.observeValueUpdateAndSetNotification()
            .map { $0.stringValue }
    }

    func write(value: String, for characteristic: Characteristic) {
        guard let data = value.data(using: .utf8) else { return }
        _ = characteristic.writeValue(data, type: .withoutResponse).subscribe(onSuccess: { _ in print("written!") })
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

private extension Characteristic {

    var stringValue: String {
        self.value.flatMap { String(data: $0, encoding: .utf8) } ?? "-"
    }

}
