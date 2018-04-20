import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class PeripheralServicesViewModel: PeripheralServicesViewModelType {

    let displayedPeripheral: Peripheral

    let bluetoothService: RxBluetoothKitService

    var servicesOutput: Observable<Result<Service, Error>> {
        return discoveredServicesSubject.asObservable()
    }

    var disconnectionOutput: Observable<Result<RxBluetoothKitService.Disconnection, Error>> {
        return bluetoothService.disconnectionReasonOutput
    }

    private let discoveredServicesSubject = PublishSubject<Result<Service, Error>>()

    private let disposeBag = DisposeBag()

    init(with bluetoothService: RxBluetoothKitService, peripheral: Peripheral) {
        self.bluetoothService = bluetoothService
        self.displayedPeripheral = peripheral
    }

    func discoverServices() {
        bluetoothService.discoverServices(for: displayedPeripheral)
        
        bluetoothService.discoveredServicesOutput.asObservable().subscribe(onNext: { [unowned self] (result) in
            switch result {
            case .success(let services):
                services.forEach { service in
                    self.discoveredServicesSubject.onNext(Result.success(service))
                }
            case .error(let error):
                self.discoveredServicesSubject.onNext(Result.error(error))
            }
        }).disposed(by: disposeBag)
    }

    func disconnect() {
        bluetoothService.disconnect(displayedPeripheral)
    }
}
