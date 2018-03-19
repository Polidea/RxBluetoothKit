import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralCharacteristicOperationsTest: BasePeripheralTest {
    var service: CBServiceMock!
    
    override func setUp() {
        super.setUp()
        
        peripheral.peripheral.state = .connected
        service = CBServiceMock()
    }
 
    func testObserveWrite() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001", service: service),
            createCharacteristic(uuid: "0x0002", service: service)
        ]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite().asObservable()
        }

        let writeEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristics[0], nil)),
            next(subscribeTime + 200, (mockCharacteristics[1], nil))
        ]
        testScheduler.createHotObservable(writeEvents).subscribe(peripheral.delegateWrapper.peripheralDidWriteValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should reveive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristics[0].uuid, "should receive event for first characteristic")
        XCTAssertEqual(obs.events[1].value.element?.uuid, mockCharacteristics[1].uuid, "should receive event for second characteristic")
    }
    
    func testObserveWriteForSpecificCharacteristic() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001", service: service),
            createCharacteristic(uuid: "0x0002", service: service)
        ]
        let characteristic = _Characteristic(characteristic: mockCharacteristics[0], peripheral: peripheral)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite(for: characteristic).asObservable()
        }
        
        let writeEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristics[0], nil)),
            next(subscribeTime + 200, (mockCharacteristics[1], nil))
        ]
        testScheduler.createHotObservable(writeEvents).subscribe(peripheral.delegateWrapper.peripheralDidWriteValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should reveive one event")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive event for correct characteristic")
    }
    
    func testWriteValueWithResponse() {
        let characteristic = _Characteristic(characteristic: createCharacteristic(uuid: "0x0001", service: service), peripheral: peripheral)
        let data = Data(bytes: [0, 1, 2, 3])
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: characteristic, type: .withResponse).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForCharacteristic.onNext((characteristic.characteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(peripheral.peripheral.writeValueWithTypeParams.count, 1, "should call writeValueWithType method for the peripheral")
        let params = peripheral.peripheral.writeValueWithTypeParams[0]
        XCTAssertTrue(params.0 == data && params.1 == characteristic.characteristic && params.2 == .withResponse, "should call writeValueWithType with correct parameters")
        XCTAssertEqual(obs.events.count, 0, "should not receive events immediately after subscription")
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events after write confirmation")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive next events with characteristic")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
    
    func testWriteValueWithoutResponse() {
        let characteristic = _Characteristic(characteristic: createCharacteristic(uuid: "0x0001", service: service), peripheral: peripheral)
        let data = Data(bytes: [0, 1, 2, 3])
        peripheral.peripheral.canSendWriteWithoutResponse = true
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: characteristic, type: .withoutResponse).asObservable()
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(peripheral.peripheral.writeValueWithTypeParams.count, 1, "should call writeValueWithType method for the peripheral")
        let params = peripheral.peripheral.writeValueWithTypeParams[0]
        XCTAssertTrue(params.0 == data && params.1 == characteristic.characteristic && params.2 == .withoutResponse, "should call writeValueWithType with correct parameters")
        XCTAssertEqual(obs.events.count, 2, "should not receive two events immediately after subscription")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive next events with characteristic")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
    
    func testWriteValueWithoutResponseWaitingOnReadiness() {
        let characteristic = _Characteristic(characteristic: createCharacteristic(uuid: "0x0001", service: service), peripheral: peripheral)
        let data = Data(bytes: [0, 1, 2, 3])
        peripheral.peripheral.canSendWriteWithoutResponse = false
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: characteristic, type: .withoutResponse).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralIsReadyToSendWriteWithoutResponse.onNext(())
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(peripheral.peripheral.writeValueWithTypeParams.count, 0, "should not call writeValueWithType method after subscription")
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.writeValueWithTypeParams.count, 1, "should call writeValueWithType method for the peripheral when peripheral is ready")
        let params = peripheral.peripheral.writeValueWithTypeParams[0]
        XCTAssertTrue(params.0 == data && params.1 == characteristic.characteristic && params.2 == .withoutResponse, "should call writeValueWithType with correct parameters")
        XCTAssertEqual(obs.events.count, 2, "should not receive two events immediately after subscription")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive next events with characteristic")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
    
    func testObserveValueUpdate() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001", service: service),
            createCharacteristic(uuid: "0x0002", service: service)
        ]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate()
        }
        
        let updateEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristics[0], nil)),
            next(subscribeTime + 200, (mockCharacteristics[1], nil))
        ]
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should reveive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristics[0].uuid, "should receive event for first characteristic")
        XCTAssertEqual(obs.events[1].value.element?.uuid, mockCharacteristics[1].uuid, "should receive event for second characteristic")
    }
    
    func testObserveValueUpdateForSpecificCharacteristic() {
        let mockCharacteristics = [
            createCharacteristic(uuid: "0x0001", service: service),
            createCharacteristic(uuid: "0x0002", service: service)
        ]
        let characteristic = _Characteristic(characteristic: mockCharacteristics[0], peripheral: peripheral)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate(for: characteristic)
        }
        
        let updateEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristics[0], nil)),
            next(subscribeTime + 200, (mockCharacteristics[1], nil))
        ]
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateValueForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should reveive one event")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive event for correct characteristic")
    }
    
     func testObserveCharacteristicIsNotifyingValue() {
        let mockCharacteristic = createCharacteristic(uuid: "0x0001", service: service)
        let characteristic = _Characteristic(characteristic: mockCharacteristic, peripheral: peripheral)

        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeNotifyValue(for: characteristic)
        }

        let updateEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristic, nil)),
            next(subscribeTime + 200, (mockCharacteristic, nil))
        ]
        
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateNotificationStateForCharacteristic).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "Should receive two events")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive event for correct characteristic")
    }
    
    func testCharacteristicIsNotifyingValueChange() {
        let mockCharacteristic = createCharacteristic(uuid: "0x0001", service: service)
        let characteristic = _Characteristic(characteristic: mockCharacteristic, peripheral: peripheral)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            characteristic.observeNotifyValue()
        }
        
        let updateEvents: [Recorded<Event<(CBCharacteristicMock, Error?)>>] = [
            next(subscribeTime + 100, (mockCharacteristic, nil)),
            next(subscribeTime + 200, (mockCharacteristic, nil))
        ]
        
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateNotificationStateForCharacteristic).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "Should receive two events")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive event for correct characteristic")
    }
    
    func testReadValue() {
        let characteristic = _Characteristic(characteristic: createCharacteristic(uuid: "0x0001", service: service), peripheral: peripheral)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.readValue(for: characteristic).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForCharacteristic.onNext((characteristic.characteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime)
        
        XCTAssertEqual(peripheral.peripheral.readValueWithCharacteristicParams.count, 1, "should call readValue method for the peripheral")
        let params = peripheral.peripheral.readValueWithCharacteristicParams[0]
        XCTAssertEqual(params, characteristic.characteristic, "should call readValue method for correct characteristic")
        XCTAssertEqual(obs.events.count, 0, "should not receive events immediately after subscription")
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events after value update")
        XCTAssertEqual(obs.events[0].value.element, characteristic, "should receive next events with characteristic")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
}
