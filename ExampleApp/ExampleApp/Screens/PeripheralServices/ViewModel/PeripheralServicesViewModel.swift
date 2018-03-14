import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    let displayedPeripheral: Peripheral

    let bluetoothService: RxBluetoothKitService

    var servicesOutput: Observable<Service> {
        return discoveredServicesSubject.asObservable()
    }

    var disconnectionOutput: Observable<RxBluetoothKitService.Disconnection> {
        return bluetoothService.disconnectionReasonOutput
    }

    var errorOutput: Observable<Error> {
        return errorOutputSubject.asObservable()
    }

    private let discoveredServicesSubject = PublishSubject<Service>()

    private let errorOutputSubject = PublishSubject<Error>()

    private let disposeBag = DisposeBag()

    init(with bluetoothService: RxBluetoothKitService, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.displayedPeripheral = peripheral
        self.bindErrorOutput()
    }

    func connect() {
        bluetoothService.discoverServices(for: displayedPeripheral)

        bluetoothService.servicesOutput.subscribe(onNext: { services in
            services.forEach { [unowned self] service in
                self.discoveredServicesSubject.onNext(service)
            }
        }, onError: { [unowned self] error in
            self.errorOutputSubject.onNext(error)
        }).disposed(by: disposeBag)
    }

    private func bindErrorOutput() {
        bluetoothService.errorOutput.bind(to: errorOutputSubject).disposed(by: disposeBag)
    }
}
