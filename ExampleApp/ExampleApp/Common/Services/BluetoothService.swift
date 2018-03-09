import Foundation
import RxBluetoothKit
import RxSwift
import RxCocoa

class RxBluetoothKitService {

    static let shared = RxBluetoothKitService()

    var scanningOutput: Observable<ScannedPeripheral> {
        return scanningSubject.asObservable()
    }

    var servicesOutput: Observable<[Service]> {
        return servicesSubject.asObservable()
    }

    var service: Service? // to samo

    private let scanningSubject: PublishSubject<ScannedPeripheral> = PublishSubject()

    private let servicesSubject: PublishSubject<[Service]> = PublishSubject()

    private let centralManager: CentralManager = CentralManager(queue: .main)

    private let scheduler: ConcurrentDispatchQueueScheduler

    private let disposeBag = DisposeBag()

    private var connectedPeripherals: [Peripheral] = []

    private var scanningDisposable: Disposable!

    init() {
        let timerQueue = DispatchQueue(label: "com.polidea.rxbluetoothkit.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
    }

    func startScanning() {
        scanningDisposable = centralManager.observeState()
                .startWith(centralManager.state)
                .filter {
                    $0 == .poweredOn
                }
                .subscribeOn(MainScheduler.instance)
                .timeout(4.0, scheduler: scheduler)
                .flatMap { [unowned self] _ -> Observable<ScannedPeripheral> in
                    return self.centralManager.scanForPeripherals(withServices: nil)
                }.bind(to: scanningSubject)
    }

    func stopScanning() {
        scanningDisposable.dispose()
    }

    func discoverServices(for peripheral: Peripheral) {
        centralManager.establishConnection(peripheral)
                .do(onNext: { [unowned self] _ in
                    self.addConnected(peripheral)
                    self.observeDisconnect(for: peripheral)
                })
                .flatMap {
                    $0.discoverServices(nil)
                }.bind(to: servicesSubject)
                .disposed(by: disposeBag)
    }

    func discoverCharacteristics() -> Observable<[Characteristic]> {
        guard let service = service else {
            return Observable.empty()
        }
        return service.discoverCharacteristics(nil).asObservable()
    }

    private func addConnected(_ peripheral: Peripheral) {
        let peripherals = connectedPeripherals.filter {
            $0 == peripheral
        }
        if peripherals.isEmpty {
            connectedPeripherals.append(peripheral)
        }
    }

    private func removeDisconnected(_ peripheral: Peripheral) {
        connectedPeripherals = connectedPeripherals.filter() {
            $0 !== peripheral
        }
    }

    private func observeDisconnect(for peripheral: Peripheral) {
        centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
            print("Disconnected: ", peripheral, reason)
            self.removeDisconnected(peripheral)
        }, onError: { error in
            print(error)
        }).disposed(by: disposeBag)
    }
}
