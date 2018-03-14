import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class CharacteristicNotificationManagerTest: XCTestCase {
    
    var manager: _CharacteristicNotificationManager!
    var peripheralMock: CBPeripheralMock!
    var wrapperMock: CBPeripheralDelegateWrapperMock!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    let subscribeTime = TestScheduler.Defaults.subscribed
    let disposeTime = TestScheduler.Defaults.disposed
    
    override func setUp() {
        super.setUp()
        setUpProperties()
    }
    
    func testObserversNotifyCalls() {
        let charMock1 = createCharacteristicMock(withUuid: CBUUID(string: "0x0000"))
        let charMock2 = createCharacteristicMock(withUuid: CBUUID(string: "0x1111"))
        let charMock3 = charMock1
        let (char1, _) = createAndSetUpObservable(characteristicMock: charMock1, time: createTimes(withOffset: 0))
        let (char2, _) = createAndSetUpObservable(characteristicMock: charMock2, time: createTimes(withOffset: 100))
        let (_, _) = createAndSetUpObservable(characteristicMock: charMock3, time: createTimes(withOffset: 200))
        
        testScheduler.advanceTo(subscribeTime + 0)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 1, "should call setNotifyValue when setting first observer")
        XCTAssertTrue(peripheralMock.setNotifyValueParams[0].0, "should correctly call setNotifyValue when setting first observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[0].1, char1.characteristic, "should correctly call setNotifyValue when setting first observer")
        
        testScheduler.advanceTo(subscribeTime + 100)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 2, "should call setNotifyValue when setting second observer")
        XCTAssertTrue(peripheralMock.setNotifyValueParams[1].0, "should correctly call setNotifyValue when setting second observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[1].1, char2.characteristic, "should correctly call setNotifyValue when setting second observer")
        
        testScheduler.advanceTo(subscribeTime + 200)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 2, "should not call setNotifyValue on third observer")
        
        testScheduler.advanceTo(disposeTime)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 2, "should not call setNotifyValue on disposing first observer")
        
        testScheduler.advanceTo(disposeTime + 100)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 3, "should call setNotifyValue when disposing second observer")
        XCTAssertFalse(peripheralMock.setNotifyValueParams[2].0, "should correctly call setNotifyValue when disposing second observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[2].1, char2.characteristic, "should correctly call setNotifyValue when disposing second observer")
        
        testScheduler.advanceTo(disposeTime + 200)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 4, "should call setNotifyValue when disposing third observer")
        XCTAssertFalse(peripheralMock.setNotifyValueParams[3].0, "should correctly call setNotifyValue when disposing third observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[3].1, char1.characteristic, "should correctly call setNotifyValue when disposing third observer")
    }
    
    func testObserversReceivingValues() {
        let charMock1 = createCharacteristicMock(withUuid: CBUUID(string: "0x0000"))
        let charMock2 = createCharacteristicMock(withUuid: CBUUID(string: "0x1111"))
        let charMock3 = charMock1
        let (char1, obs1) = createAndSetUpObservable(characteristicMock: charMock1, time: createTimes(withOffset: 0))
        let (char2, obs2) = createAndSetUpObservable(characteristicMock: charMock2, time: createTimes(withOffset: 100))
        let (char3, obs3) = createAndSetUpObservable(characteristicMock: charMock3, time: createTimes(withOffset: 200))
        let events: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime - 100, (char1.characteristic, nil)),
            next(subscribeTime, (char1.characteristic, nil)),
            next(subscribeTime + 100, (char2.characteristic, nil)),
            next(subscribeTime + 200, (char3.characteristic, nil)),
        ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.peripheralDidUpdateValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs1.events.count, 2, "should receive 2 events for first observer")
        XCTAssertEqual(obs1.events[0].value.element!.characteristic, charMock1, "should receive correct 1 event for first observer")
        XCTAssertEqual(obs1.events[1].value.element!.characteristic, charMock1, "should receive correct 2 event for first observer")
        XCTAssertEqual(obs2.events.count, 1, "should receive 1 events for second observer")
        XCTAssertEqual(obs2.events[0].value.element!.characteristic, charMock2, "should receive correct event for second observer")
        XCTAssertEqual(obs3.events.count, 1, "should receive 1 events for third observer")
        XCTAssertEqual(obs3.events[0].value.element!.characteristic, charMock3, "should receive correct event for third observer")
    }
    
    func testObserversReceivingErrors() {
        let charMock1 = createCharacteristicMock(withUuid: CBUUID(string: "0x0000"))
        let charMock2 = charMock1
        let (char1, obs1) = createAndSetUpObservable(characteristicMock: charMock1, time: createTimes(withOffset: 0))
        let (char2, obs2) = createAndSetUpObservable(characteristicMock: charMock2, time: createTimes(withOffset: 100))
        let events: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime, (char1.characteristic, nil)),
            next(subscribeTime + 50, (char1.characteristic, TestError.error)),
            next(subscribeTime + 100, (char2.characteristic, nil)),
            next(subscribeTime + 150, (char2.characteristic, TestError.error)),
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.peripheralDidUpdateValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime)
        XCTAssertEqual(obs1.events.count, 1, "should receive 1 event for first observer at time 0")
        XCTAssertEqual(obs2.events.count, 0, "should receive 0 events for second observer at time 0")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 1, "should call setNotifyValue at time 0")
        
        testScheduler.advanceTo(subscribeTime + 50)
        XCTAssertEqual(obs1.events.count, 2, "should receive 2 events for first observer at time 50")
        XCTAssertError(obs1.events[1].value, _BluetoothError.characteristicReadFailed(char1, TestError.error), "should receive correct error as 2 event for first observer at time 50")
        XCTAssertEqual(obs2.events.count, 0, "should receive 0 events for second observer at time 50")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 2, "should 2x call setNotifyValue at time 50")
        
        testScheduler.advanceTo(subscribeTime + 100)
        XCTAssertEqual(obs1.events.count, 2, "should receive 2 events for first observer at time 100")
        XCTAssertEqual(obs2.events.count, 1, "should receive 1 event for second observer at time 100")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 3, "should 3x call setNotifyValue at time 100")
        
        testScheduler.advanceTo(subscribeTime + 150)
        XCTAssertEqual(obs1.events.count, 2, "should receive 2 events for first observer at time 150")
        XCTAssertEqual(obs2.events.count, 2, "should receive 2 events for second observer at time 150")
        XCTAssertError(obs2.events[1].value, _BluetoothError.characteristicReadFailed(char2, TestError.error), "should receive correct error as 2 event for second observer at time 150")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 4, "should 4x call setNotifyValue at time 150")
    }
    
    func testObserversReceivingValuesAfterError() {
        let charMock1 = createCharacteristicMock(withUuid: CBUUID(string: "0x0000"))
        let charMock2 = charMock1
        let (char1, obs1) = createAndSetUpObservable(characteristicMock: charMock1, time: createTimes(withOffset: 0))
        let (_, obs2) = createAndSetUpObservable(characteristicMock: charMock2, time: createTimes(withOffset: 100))
        
        let events: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 50, (char1.characteristic, TestError.error)),
            next(subscribeTime + 100, (char1.characteristic, nil))
            ]
        testScheduler.createHotObservable(events).subscribe(wrapperMock.peripheralDidUpdateValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime)
        XCTAssertEqual(obs1.events.count, 0, "should receive 0 events for first observer at time 0")
        XCTAssertEqual(obs2.events.count, 0, "should receive 0 events for second observer at time 0")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 1, "should call setNotifyValue at time 0")
        
        testScheduler.advanceTo(subscribeTime + 50)
        XCTAssertEqual(obs1.events.count, 1, "should receive 1 event for first observer at time 50")
        XCTAssertEqual(obs2.events.count, 0, "should receive 0 events for second observer at time 50")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 2, "should 2x call setNotifyValue at time 50")
        
        testScheduler.advanceTo(subscribeTime + 100)
        XCTAssertEqual(obs1.events.count, 1, "should receive 1 event for first observer at time 100")
        XCTAssertEqual(obs2.events.count, 1, "should receive 0 events for second observer at time 100")
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 3, "should 3x call setNotifyValue at time 100")
        XCTAssertTrue(peripheralMock.setNotifyValueParams[2].0, "should correctly call setNotifyValue after setting second observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[2].1, char1.characteristic, "should correctly call setNotifyValue when setting second observer")
        
        testScheduler.advanceTo(disposeTime + 100)
        XCTAssertEqual(peripheralMock.setNotifyValueParams.count, 4, "should 4x call setNotifyValue when disposing second observer")
        XCTAssertFalse(peripheralMock.setNotifyValueParams[3].0, "should correctly call setNotifyValue when disposing second observer")
        XCTAssertEqual(peripheralMock.setNotifyValueParams[3].1, char1.characteristic, "should correctly call setNotifyValue when when disposing second observer")
    }
    
    // MARK: - Utils
    
    private func createAndSetUpObservable(characteristicMock: CBCharacteristicMock, time: ObservableScheduleTimes = ObservableScheduleTimes()) -> (_Characteristic, ScheduledObservable<_Characteristic>) {
        let peripheral = _Peripheral(manager: _CentralManager(), peripheral: peripheralMock, delegateWrapper: wrapperMock)
        let service = _Service(peripheral: peripheral, service: CBServiceMock())
        let characteristic = _Characteristic(characteristic: characteristicMock, service: service)
        let observer: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable(time: time) {
            self.manager.observeValueUpdateAndSetNotification(for: characteristic).asObservable()
        }
        
        return (characteristic, observer)
    }
    
    private func setUpProperties() {
        peripheralMock = CBPeripheralMock()
        wrapperMock = CBPeripheralDelegateWrapperMock()
        manager = _CharacteristicNotificationManager(peripheral: peripheralMock, delegateWrapper: wrapperMock)
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
    
    private func createTimes(withOffset offset: Int) -> ObservableScheduleTimes {
        return ObservableScheduleTimes(
            createTime: TestScheduler.Defaults.created + offset,
            subscribeTime: TestScheduler.Defaults.subscribed + offset,
            disposeTime: TestScheduler.Defaults.disposed + offset
        )
    }
    
    private func createCharacteristicMock(withUuid uuid: CBUUID) -> CBCharacteristicMock {
        let characteristicMock = CBCharacteristicMock()
        characteristicMock.uuid = uuid
        return characteristicMock
    }
}
