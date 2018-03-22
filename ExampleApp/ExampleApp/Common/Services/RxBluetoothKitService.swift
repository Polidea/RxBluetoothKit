import Foundation
import RxBluetoothKit
import RxSwift
import RxCocoa

// RxBluetoothKitService is a class encapsulating logic for most operations you might want to perform
// on a CentralManager object. Here you can see an example usage of such features as scanning for peripherals,
// discovering services and discovering peripherals.

final class RxBluetoothKitService {

    typealias Disconnection = (Peripheral, DisconnectionReason?)

    // MARK: - Public outputs

    var scanningOutput: Observable<ScannedPeripheral> {
        return scanningSubject.share(replay: 1, scope: .forever).asObservable()
    }

    var servicesOutput: Observable<[Service]> {
        return servicesSubject.asObservable()
    }

    var disconnectionReasonOutput: Observable<Disconnection> {
        return disconnectionSubject.asObservable()
    }

    var readValueOutput: Observable<Result<Characteristic, Error>> {
        return readValueSubject.asObservable()
    }

    var writeValueOutput: Observable<Result<Characteristic, Error>> {
        return writeValueSubject.asObservable()
    }

    var errorOutput: Observable<Error> {
        return errorSubject.asObservable()
    }

    // MARK: - Private subjects

    private let scanningSubject = PublishSubject<ScannedPeripheral>()

    private let servicesSubject = PublishSubject<[Service]>()

    private let disconnectionSubject = PublishSubject<Disconnection>()

    private let writeValueSubject = PublishSubject<Result<Characteristic, Error>>()

    private let readValueSubject = PublishSubject<Result<Characteristic, Error>>()

    private let errorSubject = PublishSubject<Error>()

    // MARK: - Private fields

    private let centralManager = CentralManager(queue: .main)

    private let scheduler: ConcurrentDispatchQueueScheduler

    private let disposeBag = DisposeBag()

    private var peripheralConnections: [Peripheral: Disposable] = [:]

    private var scanningDisposable: Disposable!

    private var connectionDisposable: Disposable!

    // MARK: - Initialization
    init() {
        let timerQueue = DispatchQueue(label: Constant.Strings.defaultDispatchQueueLabel)
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
    }


    // MARK: - Scanning for peripherals

    // You start from observing state of your CentralManager object. Within RxBluetoothKit v.5.0, it is crucial
    // that you use .startWith(:_) operator, and pass the initial state of your CentralManager with
    // centralManager.state.
    func startScanning() {
        scanningDisposable = centralManager.observeState()
                .startWith(centralManager.state)
                .filter {
                    $0 == .poweredOn
                }
                .subscribeOn(MainScheduler.instance)
                .timeout(4.0, scheduler: scheduler)
                .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    return self.centralManager.scanForPeripherals(withServices: nil)
                }.bind(to: scanningSubject)
    }

    func readValueFrom(_ characteristic: Characteristic) {
        characteristic.readValue().subscribe(onSuccess: { [unowned self] characteristic in
            self.readValueSubject.onNext(Result.success(characteristic))
        }, onError: { [unowned self] error in
            self.readValueSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }

    // If you wish to stop scanning for peripherals, you need to dispose the Disposable object, created when
    // you either subscribe for events from an observable returned by centralManager.scanForPeripherals(:_), or you bind
    // an observer to it. Check starScanning() above for details.
    func stopScanning() {
        scanningDisposable.dispose()
    }


    // MARK: - Discovering Services

    // When you discover a service, first you need to establish a connection with a peripheral. Then you call
    // discoverServices(:_) that peripheral object.
    func discoverServices(for peripheral: Peripheral) {
        let disposable = peripheral.establishConnection()
                .do(onNext: { [weak self] _ in
                    self?.observeDisconnect(for: peripheral)
                })
                .flatMap {
                    $0.discoverServices(nil)
                }.subscribe(onNext: { [weak self] services in
                    self?.servicesSubject.onNext(services)
                }, onError: { (error) in
                    print(error)
                })

        peripheralConnections[peripheral] = disposable
    }

    // Disposal of a given connection disposable disconnects automatically from a peripheral
    //So firstly, you discconect from a perpiheral and then you remove of disconnected Peripheral from the Peripheral's collection.
    func disconnect(_ peripheral: Peripheral) {
        guard let disposable = peripheralConnections[peripheral] else {
            return
        }
        disposable.dispose()
        peripheralConnections[peripheral] = nil
    }

    // MARK: - Discovering Characteristics
    func discoverCharacteristics(for service: Service) -> Observable<[Characteristic]> {
        return service.discoverCharacteristics(nil).asObservable()
    }

    func writeValueTo(characteristic: Characteristic, data: Data) {
        guard let writeType = characteristic.determineWriteType() else {
            return
        }

        characteristic.writeValue(data, type: writeType).subscribe(onSuccess: { [unowned self] characteristic in
            self.writeValueSubject.onNext(Result.success(characteristic))
        }, onError: { [unowned self] error in
            self.writeValueSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }

    // When you observe disconnection from a peripheral, you want to be sure that you take an action on both .next and
    // .error events. For instance, when your device enters BluetoothState.poweredOff, you will receive an .error event.
    private func observeDisconnect(for peripheral: Peripheral) {
        centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
            self.disconnectionSubject.onNext((peripheral, reason))
            self.disconnect(peripheral)
        }, onError: { [unowned self] error in
            self.errorSubject.onNext(error)
        }).disposed(by: disposeBag)
    }
}
