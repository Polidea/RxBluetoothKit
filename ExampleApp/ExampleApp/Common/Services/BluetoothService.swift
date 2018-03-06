import Foundation
import RxBluetoothKit
import RxSwift
import RxCocoa

class RxBluetoothKitService {

    static let shared = RxBluetoothKitService()

    var scanningOutput: Observable<ScannedPeripheral> {
        return scanningSubject.asObservable()
    }
    
    var peripheral: Peripheral?

    private let scanningSubject: PublishSubject<ScannedPeripheral> = PublishSubject()

    private let centralManager: CentralManager = CentralManager(queue: .main)

    private let scheduler: ConcurrentDispatchQueueScheduler

    private let disposeBag = DisposeBag()

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
                .timeout(4.0, scheduler: scheduler)
                .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    return self.centralManager.scanForPeripherals(withServices: nil)
                }.bind(to: scanningSubject)
    }

    func stopScanning() {
        scanningDisposable.dispose()
    }

    func connectToPeripheral() {
        guard let peripheral = self.peripheral else {
            return
        }
        centralManager.establishConnection(peripheral).flatMap {
            $0.discoverServices(nil)
        }.subscribe(onNext: { services in
            print(services)
        }).disposed(by: disposeBag)
    }
}
