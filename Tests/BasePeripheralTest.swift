import XCTest
import RxTest
import RxSwift
import CoreBluetooth

class BasePeripheralTest: XCTestCase {
    var peripheral: _Peripheral!
    var centralManagerMock: _CentralManager!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    override func setUp() {
        super.setUp()
        
        centralManagerMock = _CentralManager()
        let peripheralMock = CBPeripheralMock()
        let delegateWrapperMock = CBPeripheralDelegateWrapperMock()
        let notificationManager = CharacteristicNotificationManagerMock(peripheral: peripheralMock, delegateWrapper: delegateWrapperMock)
        peripheral = _Peripheral(manager: centralManagerMock, peripheral: peripheralMock, delegateWrapper: delegateWrapperMock, notificationManager: notificationManager)
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
        
        centralManagerMock.centralManager.state = .poweredOn
    }
    
    // MARK: - Utils
    
    func createService(uuid: String) -> CBServiceMock {
        let service = CBServiceMock()
        service.uuid = CBUUID(string: uuid)
        return service
    }
    
    func createCharacteristic(uuid: String, service: CBServiceMock? = nil) -> CBCharacteristicMock {
        let characteristic = CBCharacteristicMock()
        characteristic.uuid = CBUUID(string: uuid)
        characteristic.service = service
        
        return characteristic
    }
    
    func createDescriptor(uuid: String, characteristic: CBCharacteristicMock? = nil) -> CBDescriptorMock {
        let descriptor = CBDescriptorMock()
        descriptor.uuid = CBUUID(string: uuid)
        descriptor.characteristic = characteristic
        
        return descriptor
    }
}

