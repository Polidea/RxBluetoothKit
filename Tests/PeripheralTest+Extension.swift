import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralExtensionTest: BasePeripheralTest {
    
    override func setUp() {
        super.setUp()
        
        peripheral.peripheral.state = .connected
    }
    
    func testServiceWithIdentifier() {
        let mockServices = [
            createService(uuid: "0x0000"),
            createService(uuid: "0x0001")
        ]
        let serviceId = ServiceData(uuid: mockServices[0].uuid)
        
        let obs: ScheduledObservable<_Service> = testScheduler.scheduleObservable {
            self.peripheral.service(with: serviceId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = mockServices
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext((mockServices, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockServices[0].uuid, "should receive an event with the service")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receive completed event")
    }
    
    func testServiceWithIdentifierNoServiceFound() {
        let serviceId = ServiceData(uuid: CBUUID(string: "0x0001"))
        
        let obs: ScheduledObservable<_Service> = testScheduler.scheduleObservable {
            self.peripheral.service(with: serviceId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = [self.createService(uuid: "0x0000")]
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext(([self.createService(uuid: "0x0000")], nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, RxError.noElements, "should receive noElements error")
    }
    
    func testCharacteristicWithIdentifier() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.characteristic(with: characteristicId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = [mockService]
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext(([mockService], nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            mockService.characteristics = [mockCharacteristic]
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((mockService, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristic.uuid, "should receive an event with the characteristic")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receive completed event")
    }
    
    func testCharacteristicWithIdentifierNoCharacteristicFound() {
        let mockService = createService(uuid: "0x0000")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: CBUUID(string: "0x0001"), service: serviceId)
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.characteristic(with: characteristicId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = [mockService]
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext(([mockService], nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            mockService.characteristics = []
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((mockService, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 200)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertError(obs.events[0].value, RxError.noElements, "should receive noElements error")
    }
    
    func testDescriptorWithIdentifier() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)
        
        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.descriptor(with: descriptorId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = [mockService]
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext(([mockService], nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            mockService.characteristics = [mockCharacteristic]
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((mockService, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 300) {
            mockCharacteristic.descriptors = [mockDescriptor]
            self.peripheral.delegateWrapper.peripheralDidDiscoverDescriptorsForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 300)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptor.uuid, "should receive an event with descriptor")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receice completed event")
    }
    
    func testDescriptorWithIdentifierNoDescriptorFound() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)
        
        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.descriptor(with: descriptorId).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.peripheral.services = [mockService]
            self.peripheral.delegateWrapper.peripheralDidDiscoverServices.asObserver().onNext(([mockService], nil))
        }
        testScheduler.scheduleAt(subscribeTime + 200) {
            mockService.characteristics = [mockCharacteristic]
            self.peripheral.delegateWrapper.peripheralDidDiscoverCharacteristicsForService.asObserver().onNext((mockService, nil))
        }
        testScheduler.scheduleAt(subscribeTime + 300) {
            mockCharacteristic.descriptors = []
            self.peripheral.delegateWrapper.peripheralDidDiscoverDescriptorsForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 300)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one events")
        XCTAssertError(obs.events[0].value, RxError.noElements, "should receive no elements error")
    }
    
    func testCharacteristicObserveWrite() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite(for: characteristicId)
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristic.uuid, "should receive an event with the characteristic")
    }
    
    func testCharacteristicWriteValueWithResponse() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let data = Data(bytes: [0, 1, 2, 3])
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: characteristicId, type: .withResponse).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForCharacteristic.onNext((mockCharacteristic, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristic.uuid, "should receive next events with characteristic")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }
    
    func testCharacteristicObserveValueUpdate() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate(for: characteristicId)
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristic.uuid, "should receive next event with characteristic")
    }
    
    func testCharacteristicReadValue() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        
        let obs: ScheduledObservable<_Characteristic> = testScheduler.scheduleObservable {
            self.peripheral.readValue(for: characteristicId).asObservable()
        }
        
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        XCTAssertEqual(obs.events.count, 2, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockCharacteristic.uuid, "should receive an evenet with the characteristic")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receive completed event")
    }
    
    func testDescriptorsDiscover() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        
        let obs: ScheduledObservable<[_Descriptor]> = testScheduler.scheduleObservable {
            self.peripheral.discoverDescriptors(for: characteristicId).asObservable()
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            mockCharacteristic.descriptors = [mockDescriptor]
            self.peripheral.delegateWrapper.peripheralDidDiscoverDescriptorsForCharacteristic.asObserver().onNext((mockCharacteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        let foundDescriptors = obs.events[0].value.element!
        XCTAssertEqual(foundDescriptors.count, 1, "should receive array with one descriptor")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receice completed event")
    }
    
    func testDescriptorObserveWrite() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)

        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        mockCharacteristic.descriptors = [mockDescriptor]

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeWrite(for: descriptorId)
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForDescriptor.asObserver().onNext((mockDescriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptor.uuid, "should receive an event with the descriptor")
    }

    func testDescriptorWriteValueWithResponse() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)
        let data = Data(bytes: [0, 1, 2, 3])

        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        mockCharacteristic.descriptors = [mockDescriptor]

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.writeValue(data, for: descriptorId).asObservable()
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidWriteValueForDescriptor.onNext((mockDescriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 2, "should receive two events")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptor.uuid, "should receive next events with descriptor")
        XCTAssertTrue(obs.events[1].value == .completed, "should receive completed event")
    }

    func testDescriptorObserveValueUpdate() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)

        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        mockCharacteristic.descriptors = [mockDescriptor]

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.observeValueUpdate(for: descriptorId)
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForDescriptor.asObserver().onNext((mockDescriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)

        XCTAssertEqual(obs.events.count, 1, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptor.uuid, "should receive next event with descriptor")
    }

    func testDescriptorReadValue() {
        let mockService = createService(uuid: "0x0000")
        let mockCharacteristic = createCharacteristic(uuid: "0x0001")
        let mockDescriptor = createDescriptor(uuid: "0x0002")
        let serviceId = ServiceData(uuid: mockService.uuid)
        let characteristicId = CharacteristicData(uuid: mockCharacteristic.uuid, service: serviceId)
        let descriptorId = DescriptorData(uuid: mockDescriptor.uuid, characteristic: characteristicId)
        
        self.peripheral.peripheral.services = [mockService]
        mockService.characteristics = [mockCharacteristic]
        mockCharacteristic.descriptors = [mockDescriptor]

        let obs: ScheduledObservable<_Descriptor> = testScheduler.scheduleObservable {
            self.peripheral.readValue(for: descriptorId).asObservable()
        }

        testScheduler.scheduleAt(subscribeTime + 100) {
            self.peripheral.delegateWrapper.peripheralDidUpdateValueForDescriptor.asObserver().onNext((mockDescriptor, nil))
        }

        testScheduler.advanceTo(subscribeTime + 100)
        XCTAssertEqual(obs.events.count, 2, "should receive one event")
        XCTAssertEqual(obs.events[0].value.element?.uuid, mockDescriptor.uuid, "should receive an evenet with the descriptor")
        XCTAssertTrue(obs.events[1].value.isCompleted, "should receive completed event")
    }
}

struct ServiceData: ServiceIdentifier {
    var uuid: CBUUID
}

struct CharacteristicData: CharacteristicIdentifier {
    var uuid: CBUUID
    var service: ServiceIdentifier
}

struct DescriptorData: DescriptorIdentifier {
    var uuid: CBUUID
    var characteristic: CharacteristicIdentifier
}
