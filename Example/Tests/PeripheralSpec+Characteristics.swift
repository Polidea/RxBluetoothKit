////
////  PeripheralSpec.swift
////  RxBluetoothKit
////
////  Created by Kacper Harasim on 24.02.2016.
////
//
import Quick
import Nimble
@testable
import RxBluetoothKit
import RxTests
import RxSwift
import CoreBluetooth


class PeripheralSpecCharacteristics : QuickSpec {

    //Propagating errors too...
    override func spec() {
        
        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler : TestScheduler!
        var fakePeripheral: FakePeripheral!
        var peripheral: Peripheral!
        var fakeService: FakeService!
        var service: Service!
        var fakeCharacteristic: FakeCharacteristic!
        var characteristic: Characteristic!
        let statesWithErrors = BluetoothError.invalidStateErrors

        var eventTime: Int!
        var errorTime: Int!
        beforeEach {
            testScheduler = TestScheduler(initialClock: 0)

            fakePeripheral = FakePeripheral()
            fakeCentralManager = FakeCentralManager()
            manager = BluetoothManager(centralManager: fakeCentralManager)
            peripheral = Peripheral(manager: manager, peripheral: fakePeripheral)
            fakeService = FakeService()
            service = Service(peripheral: peripheral, service: fakeService)
            fakeCharacteristic = FakeCharacteristic(service: fakeService)
            characteristic = Characteristic(characteristic: fakeCharacteristic, service: service)
            eventTime = 230
            errorTime = 240
        }
        
        
        describe("characteristic") {
            var identifiers: [CBUUID]!
            beforeEach {
                identifiers = [CBUUID()]
            }
            describe("discover") {
                var characteristicsDiscoverObserver: ScheduledObservable<[Characteristic]>!
                var discoverCharacteristicsMethodObserver: TestableObserver<([CBUUID]?, RxServiceType)>!
                beforeEach {
                    fakePeripheral.discoverCharacteristicsTO = testScheduler.createObserver(([CBUUID]?, RxServiceType))
                    discoverCharacteristicsMethodObserver = fakePeripheral.discoverCharacteristicsTO
                    characteristicsDiscoverObserver = testScheduler.scheduleObservable {
                        return peripheral.discoverCharacteristics(identifiers, service: service)
                    }
                }
                context("before subscribe to discover") {
                    it("should not call discover before subscribe") {
                        expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe to discover with success characteristic discovery ") {
                    var fakeChars: [FakeCharacteristic]!
                    beforeEach {
                        fakeChars = [FakeCharacteristic(service: fakeService)]
                        fakeService.characteristics = fakeChars.map { $0 as RxCharacteristicType }
                        
                        
                        let event: Event<(RxServiceType, NSError?)> = Event.Next(fakeService as RxServiceType, nil)
                        let service: [Recorded<Event<(RxServiceType, NSError?)>>] = [Recorded(time: eventTime, event: event)]
                        fakePeripheral.rx_didDiscoverCharacteristicsForService = testScheduler.createHotObservable(service).asObservable()

                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call discover") {
                        expect(discoverCharacteristicsMethodObserver.events.count).to(equal(1))
                    }
                    
                    it("should call discover with proper uuids") {
                        expect(discoverCharacteristicsMethodObserver.events[0].value.element!.0).to(equal(identifiers))
                    }
                    it("should call discover characteristic  for proper service") {
                        expect(discoverCharacteristicsMethodObserver.events[0].value.element!.1 == fakeService)
                    }
                    describe("discovered characteristic") {
                        var characteristicsDiscovered:  [Characteristic]?
                        
                        beforeEach {
                            if let c = characteristicsDiscoverObserver.events.first?.value.element {
                                characteristicsDiscovered = c
                            }
                        }
                        it("should return characteristics") {
                            expect(characteristicsDiscovered).toNot(beNil())
                        }
                        it("should return proper characteristics") {
                            expect(characteristicsDiscovered!.map{ $0.characteristic } == fakeService.characteristics!)
                        }
                    }
                }
                context("after subscribe with failed discovery") {
                    beforeEach {
                        let tuple: (RxServiceType, NSError?) = (fakeService as RxServiceType, NSError(domain: "ERROR", code: 200, userInfo: nil))
                        let event: Event<(RxServiceType, NSError?)> = .Next(tuple)
                        let service: [Recorded<Event<(RxServiceType, NSError?)>>] = [Recorded(time: eventTime, event: event)]
                        fakePeripheral.rx_didDiscoverCharacteristicsForService = testScheduler.createHotObservable(service).asObservable()
                        testScheduler.advanceTo(250)
                    }
                    describe("error returned") {
                        it("should return event") {
                            expect(characteristicsDiscoverObserver.events.count).to(equal(1))
                        }
                        it("Should return coneection failed error") {
                            expectError(characteristicsDiscoverObserver.events[0].value, errorType: BluetoothError.CharacteristicsDiscoveryFailed(service, nil))
                        }
                    }
                }
                context("error propagation ble wrong state") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        
                        context("before subscribe") {
                            it("should not call discover  before subscribe") {
                                expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicsDiscoverObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicsDiscoverObserver.events[0].value, errorType: error)
                            }
                        }
                        
                        context("after subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: errorTime, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call connect on central manager") {
                                expect(discoverCharacteristicsMethodObserver.events.count == 1)
                            }
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                            }
                            it("should get event error") {
                                expect(characteristicsDiscoverObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicsDiscoverObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
                context("error propagation device while device disconnects at some time") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe and getting wrong state on start by event") {
                        beforeEach {
                            fakePeripheral.state = .Disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(characteristicsDiscoverObserver.events.count > 0)
                        }
                        it("should return proper error") {
                            expectError(characteristicsDiscoverObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                        }
                    }
                    context("after subscribe and getting wrong state after function is called") {
                        beforeEach {
                            //State is good on start.
                            fakeCentralManager.state = .PoweredOn
                            fakePeripheral.state = .Connected
                            //Different types of errors ::
                            let event: Event<(RxPeripheralType, NSError?)> = Event.Next(fakePeripheral as RxPeripheralType, nil)
                            let scans: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: errorTime, event: event)]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        it("should call discover characteristics method") {
                            expect(discoverCharacteristicsMethodObserver.events.count == 1)
                        }
                        context("getting wrong state in the middle of discover") {
                            it("should get event error") {
                                expect(characteristicsDiscoverObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicsDiscoverObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }
            
            describe("writing to characteristic") {
                
                var data: NSData!
                let writeType: CBCharacteristicWriteType = CBCharacteristicWriteType.WithResponse
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var writeValueForCharacteristicMethodObserver: TestableObserver<(NSData, RxCharacteristicType, CBCharacteristicWriteType)>!
                
                beforeEach {
                    fakePeripheral.writeValueForCharacteristicTypeTO = testScheduler.createObserver((NSData, RxCharacteristicType, CBCharacteristicWriteType))
                    writeValueForCharacteristicMethodObserver = fakePeripheral.writeValueForCharacteristicTypeTO
                    data = "A".dataUsingEncoding(NSUTF8StringEncoding)
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.writeValue(data, forCharacteristic: characteristic, type: writeType)
                    }
                }
                
                context("before subscribe") {
                    it("should not call write before subscribe") {
                        expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with success write") {
                    beforeEach {
                        
                        let disconnect: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: errorTime, event: .Next(fakePeripheral as RxPeripheralType, nil))]
                        fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(disconnect).asObservable()
                        
                        let write: [Recorded<Event<(RxCharacteristicType, NSError?)>>] = [Recorded(time: eventTime, event: .Next(fakeCharacteristic as RxCharacteristicType, nil))]
                        fakePeripheral.rx_didWriteValueForCharacteristic = testScheduler.createHotObservable(write).asObservable()
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call write") {
                        expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(1))
                    }
                    it("should call write with proper data") {
                        expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.0).to(equal(data))
                    }
                    it("should call write to proper characteristic") {
                        expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic)
                    }
                    it("should call write with proper write type") {
                        expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.2 == writeType)

                    }
                    
                    describe("result of call") {
                        var characteristicWrittenTo: Characteristic?
                        
                        beforeEach {
                            if let c = characteristicObserver.events.first?.value.element {
                                characteristicWrittenTo = c
                            }
                        }
                        it("should return characteristic") {
                            expect(characteristicWrittenTo).toNot(beNil())
                        }
                        it("should return proper characteristic") {
                            expect(characteristicWrittenTo!.characteristic == fakeCharacteristic)
                        }
                    }
                }
                context("after subscribe with failed write") {
                    
                    beforeEach {
                        let tuple: (RxCharacteristicType, NSError?) = (fakeCharacteristic as RxCharacteristicType, NSError(domain: "ERROR", code: 200, userInfo: nil))
                        let write: [Recorded<Event<(RxCharacteristicType, NSError?)>>] = [Recorded(time: eventTime, event: .Next(tuple))]
                        fakePeripheral.rx_didWriteValueForCharacteristic = testScheduler.createHotObservable(write).asObservable()
                        testScheduler.advanceTo(250)
                    }
                    describe("error returned") {
                        it("should return event") {
                            expect(characteristicObserver.events.count).to(equal(1))
                        }
                        it("Should return coneection failed error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.CharacteristicWriteFailed(characteristic, nil))
                        }
                    }
                }
                context("error propagation ble wrong state") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                        
                        context("After subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: 240, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call connect on central manager") {
                                expect(writeValueForCharacteristicMethodObserver.events.count == 1)
                            }
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
                context("error propagation device disconnect") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    
                    context("after subscribe and getting wrong state on start by event") {
                        beforeEach {
                            fakePeripheral.state = .Disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(characteristicObserver.events.count > 0)
                        }
                        it("should return proper error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                        }
                    }
                    context("After subscribe and getting wrong state after function is called") {
                        beforeEach {
                            //State is good on start.
                            fakeCentralManager.state = .PoweredOn
                            fakePeripheral.state = .Connected
                            //Different types of errors ::
                            let event: Event<(RxPeripheralType, NSError?)> = Event.Next(fakePeripheral as RxPeripheralType, nil)
                            let scans: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: 240, event: event)]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        it("Should call discover services") {
                            expect(writeValueForCharacteristicMethodObserver.events.count == 1)
                        }
                        context("getting wrong state in the middle of discover") {
                            beforeEach {
                                fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((fakePeripheral, nil))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }
            
            describe("reading") {
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var readValueForCharacteristicMethodObserver: TestableObserver<(RxCharacteristicType)>!
                
                beforeEach {
                    fakePeripheral.readValueForCharacteristicTO = testScheduler.createObserver(RxCharacteristicType)
                    readValueForCharacteristicMethodObserver = fakePeripheral.readValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.readValueForCharacteristic(characteristic)
                    }
                }
                
                context("before subscribe") {
                    it("should not call write before subscribe") {
                        expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with success read") {
                    beforeEach {
                        fakePeripheral.rx_didUpdateValueForCharacteristic = Observable.just((fakeCharacteristic, nil))
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call read") {
                        expect(readValueForCharacteristicMethodObserver.events.count).to(equal(1))
                    }
                    it("should call read with proper characteristic") {
                        expect(readValueForCharacteristicMethodObserver.events[0].value.element! == fakeCharacteristic)
                    }

                    describe("result of call") {
                        var characteristicToRead: Characteristic?
                        
                        beforeEach {
                            if let c = characteristicObserver.events.first?.value.element {
                                characteristicToRead = c
                            }
                        }
                        it("should return characteristic") {
                            expect(characteristicToRead).toNot(beNil())
                        }
                        it("should return proper characteristic") {
                            expect(characteristicToRead!.characteristic == fakeCharacteristic)
                        }
                    }
                }
                context("after subscribe with failed read") {
                    beforeEach {
                        fakePeripheral.rx_didUpdateValueForCharacteristic = Observable.just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                        testScheduler.advanceTo(250)
                    }
                    describe("error returned") {
                        it("should return event") {
                            expect(characteristicObserver.events.count).to(equal(1))
                        }
                        it("Should return coneection failed error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.CharacteristicReadFailed(characteristic, nil))
                        }
                    }
                }
                context("error propagation ble wrong state") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                        
                        context("After subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: 240, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call connect on central manager") {
                                expect(readValueForCharacteristicMethodObserver.events.count == 1)
                            }
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
                context("error propagation device disconnect") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    
                    context("after subscribe and getting wrong state on start by event") {
                        beforeEach {
                            fakePeripheral.state = .Disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(characteristicObserver.events.count > 0)
                        }
                        it("should return proper error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                        }
                    }
                    context("After subscribe and getting wrong state after function is called") {
                        beforeEach {
                            //State is good on start.
                            fakeCentralManager.state = .PoweredOn
                            fakePeripheral.state = .Connected
                            //Different types of errors ::
                            let event: Event<(RxPeripheralType, NSError?)> = Event.Next(fakePeripheral as RxPeripheralType, nil)
                            let scans: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: 240, event: event)]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        it("Should call discover services") {
                            expect(readValueForCharacteristicMethodObserver.events.count == 1)
                        }
                        context("getting wrong state in the middle of discover") {
                            beforeEach {
                                fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((fakePeripheral, nil))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }
            describe("set notify") {
                
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var setNotifyCharacteristicMethodObserver: TestableObserver<(Bool, RxCharacteristicType)>!
                beforeEach {
                    
                    fakePeripheral.setNotifyValueForCharacteristicTO = testScheduler.createObserver((Bool, RxCharacteristicType))
                    setNotifyCharacteristicMethodObserver = fakePeripheral.setNotifyValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        //TODO: Think about checking enabled value - it could be self test check?
                        return peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
                
                context("before subscribe") {
                    it("should not set any value before subscribe") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with success read") {
                    beforeEach {
                        //TODO: Think about checking enabled value - it could be self test check?
                        fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = Observable.just((fakeCharacteristic, nil))
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call read") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                    }
                    it("should call read with proper characteristic") {
                        expect(setNotifyCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic)
                    }
                    
                    describe("result of call") {
                        var characteristicToRead: Characteristic?
                        
                        beforeEach {
                            if let c = characteristicObserver.events.first?.value.element {
                                characteristicToRead = c
                            }
                        }
                        it("should return characteristic") {
                            expect(characteristicToRead).toNot(beNil())
                        }
                        it("should return proper characteristic") {
                            expect(characteristicToRead!.characteristic == fakeCharacteristic)
                        }
                    }
                }
                context("after subscribe with failed read") {
                    beforeEach {
                        fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = Observable.just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                        testScheduler.advanceTo(250)
                    }
                    describe("error returned") {
                        it("should return event") {
                            expect(characteristicObserver.events.count).to(equal(1))
                        }
                        it("Should return coneection failed error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.CharacteristicNotifyChangeFailed(characteristic, nil))
                        }
                    }
                }
                context("error propagation ble wrong state") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                        
                        context("After subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: 240, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call connect on central manager") {
                                expect(setNotifyCharacteristicMethodObserver.events.count == 1)
                            }
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
                context("error propagation device disconnect") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    
                    context("after subscribe and getting wrong state on start by event") {
                        beforeEach {
                            fakePeripheral.state = .Disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(characteristicObserver.events.count > 0)
                        }
                        it("should return proper error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                        }
                    }
                    context("After subscribe and getting wrong state after function is called") {
                        beforeEach {
                            //State is good on start.
                            fakeCentralManager.state = .PoweredOn
                            fakePeripheral.state = .Connected
                            //Different types of errors ::
                            let event: Event<(RxPeripheralType, NSError?)> = Event.Next(fakePeripheral as RxPeripheralType, nil)
                            let scans: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: 240, event: event)]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        it("Should call discover services") {
                            expect(setNotifyCharacteristicMethodObserver.events.count == 1)
                        }
                        context("getting wrong state in the middle of discover") {
                            beforeEach {
                                fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((fakePeripheral, nil))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }

            }
            describe("monitor updates") {
                
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var setNotifyCharacteristicMethodObserver: TestableObserver<(Bool, RxCharacteristicType)>!
                beforeEach {
                    
                    fakePeripheral.setNotifyValueForCharacteristicTO = testScheduler.createObserver((Bool, RxCharacteristicType))
                    setNotifyCharacteristicMethodObserver = fakePeripheral.setNotifyValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        //TODO: Think about checking enabled value - it could be self test check?
                        return peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
                
                context("before subscribe") {
                    it("should not set any value before subscribe") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with success read") {
                    beforeEach {
                        //TODO: Think about checking enabled value - it could be self test check?
                        fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = Observable.just((fakeCharacteristic, nil))
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call read") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                    }
                    it("should call read with proper characteristic") {
                        expect(setNotifyCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic)
                    }
                    
                    describe("result of call") {
                        var characteristicToRead: Characteristic?
                        
                        beforeEach {
                            if let c = characteristicObserver.events.first?.value.element {
                                characteristicToRead = c
                            }
                        }
                        it("should return characteristic") {
                            expect(characteristicToRead).toNot(beNil())
                        }
                        it("should return proper characteristic") {
                            expect(characteristicToRead!.characteristic == fakeCharacteristic)
                        }
                    }
                }
                context("after subscribe with failed read") {
                    beforeEach {
                        fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = Observable.just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                        testScheduler.advanceTo(250)
                    }
                    describe("error returned") {
                        it("should return event") {
                            expect(characteristicObserver.events.count).to(equal(1))
                        }
                        it("Should return coneection failed error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.CharacteristicNotifyChangeFailed(characteristic, nil))
                        }
                    }
                }
                context("error propagation ble wrong state") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                        
                        context("After subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: 240, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call connect on central manager") {
                                expect(setNotifyCharacteristicMethodObserver.events.count == 1)
                            }
                            beforeEach {
                                fakeCentralManager.rx_didUpdateState = Observable.just(state)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
                context("error propagation device disconnect") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    
                    context("after subscribe and getting wrong state on start by event") {
                        beforeEach {
                            fakePeripheral.state = .Disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(characteristicObserver.events.count > 0)
                        }
                        it("should return proper error") {
                            expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                        }
                    }
                    context("After subscribe and getting wrong state after function is called") {
                        beforeEach {
                            //State is good on start.
                            fakeCentralManager.state = .PoweredOn
                            fakePeripheral.state = .Connected
                            //Different types of errors ::
                            let event: Event<(RxPeripheralType, NSError?)> = Event.Next(fakePeripheral as RxPeripheralType, nil)
                            let scans: [Recorded<Event<(RxPeripheralType, NSError?)>>] = [Recorded(time: 240, event: event)]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        it("Should call discover services") {
                            expect(setNotifyCharacteristicMethodObserver.events.count == 1)
                        }
                        context("getting wrong state in the middle of discover") {
                            beforeEach {
                                fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((fakePeripheral, nil))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(characteristicObserver.events[0].value, errorType: BluetoothError.PeripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
                
            }
        }
    }
}
