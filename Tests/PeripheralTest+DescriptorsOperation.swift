import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralDescriptorOperationsTest: BasePeripheralTest {
    var characteristic: CBCharacteristicMock!
    
    override func setUp() {
        super.setUp()
        
        let serviceMock = CBServiceMock()
        characteristic = createCharacteristic(uuid: "0x0001", service: nil)
        characteristic.service = serviceMock
        peripheral.peripheral.state = .connected
    }
    
    func testObserveWrite() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic)
        ]
        
        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite().asObservable()
        }
        
        let writeEvents: [Recorded<Event<(CBDescriptorMock, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (mockDescriptors[0], nil)),
            Recorded.next(subscribeTime + 200, (mockDescriptors[1], nil))
        ]
        testScheduler.createHotObservable(writeEvents).subscribe(peripheral.delegateWrapper.peripheralDidWriteValueForDescriptor).disposed(by: disposeBag)
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should reveive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptors[0].uuid, "should receive event for first descriptor")
        XCTAssertEqual(obs.events[1].value.element?.uuid, mockDescriptors[1].uuid, "should receive event for second descriptor")
    }
    
    func testObserveWriteForSpecificDescriptor() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic)
        ]
        let descriptor = _Descriptor(descriptor: mockDescriptors[0], peripheral: peripheral)

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite(for: descriptor).asObservable()
        }

        let writeEvents: [Recorded<Event<(CBDescriptorMock, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (mockDescriptors[0], nil)),
            Recorded.next(subscribeTime + 200, (mockDescriptors[1], nil))
        ]
        testScheduler.createHotObservable(writeEvents).subscribe(peripheral.delegateWrapper.peripheralDidWriteValueForDescriptor).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should reveive one event")
        XCTAssertEqual(obs.events[0].value.element, descriptor, "should receive event for correct descriptor")
    }

    func testWriteValue() throws {
        let descriptor = XCTUnwrap(_Descriptor(descriptor: createDescriptor(uuid: "0x0002", characteristic: characteristic), peripheral: peripheral))
        let data = Data([0, 1, 2, 3])

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: descriptor).asObservable()
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForDescriptor.onNext((descriptor.descriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheral.peripheral.writeValueWithDescriptorParams.count, 1, "should call writeValue method for the peripheral")
        let params = peripheral.peripheral.writeValueWithDescriptorParams[0]
        XCTAssertTrue(params.0 == data && params.1 == descriptor.descriptor, "should call writeValue with correct parameters")
        XCTAssertEqual(obs.events.count, 0, "should not receive events immediately after subscription")

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 2, "should receive two events after write confirmation")
        XCTAssertEqual(obs.events[0].value.element, descriptor, "should receive next events with descriptor")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }

    func testObserveValueUpdate() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic)
        ]

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate()
        }

        let updateEvents: [Recorded<Event<(CBDescriptorMock, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (mockDescriptors[0], nil)),
            Recorded.next(subscribeTime + 200, (mockDescriptors[1], nil))
        ]
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateValueForDescriptor).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 2, "should reveive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptors[0].uuid, "should receive event for first descriptor")
        XCTAssertEqual(obs.events[1].value.element?.uuid, mockDescriptors[1].uuid, "should receive event for second descriptor")
    }

    func testObserveValueUpdateForSpecificDescriptor() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic)
        ]
        let descriptor = _Descriptor(descriptor: mockDescriptors[0], peripheral: peripheral)

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate(for: descriptor)
        }

        let updateEvents: [Recorded<Event<(CBDescriptorMock, Error?)>>] = [
            Recorded.next(subscribeTime + 100, (mockDescriptors[0], nil)),
            Recorded.next(subscribeTime + 200, (mockDescriptors[1], nil))
        ]
        testScheduler.createHotObservable(updateEvents).subscribe(peripheral.delegateWrapper.peripheralDidUpdateValueForDescriptor).disposed(by: disposeBag)

        testScheduler.advanceTo(subscribeTime + 200)

        XCTAssertEqual(obs.events.count, 1, "should reveive one event")
        XCTAssertEqual(obs.events[0].value.element, descriptor, "should receive event for correct descriptor")
    }

    func testReadValue() throws {
        let descriptor = XCTUnwrap(_Descriptor(descriptor: createDescriptor(uuid: "0x0001", characteristic: characteristic), peripheral: peripheral))

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.readValue(for: descriptor).asObservable()
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForDescriptor.onNext((descriptor.descriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheral.peripheral.readValueWithDescriptorParams.count, 1, "should call readValue method for the peripheral")
        let params = peripheral.peripheral.readValueWithDescriptorParams[0]
        XCTAssertEqual(params, descriptor.descriptor, "should call readValue method for correct descriptor")
        XCTAssertEqual(obs.events.count, 0, "should not receive events immediately after subscription")

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 2, "should receive two events after value update")
        XCTAssertEqual(obs.events[0].value.element, descriptor, "should receive next events with descriptor")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
}

