// The MIT License (MIT)
//
// Copyright (c) 2016 Polidea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Quick
import Nimble
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth


class PeripheralCharacteristicsSpec: QuickSpec {

    override func spec() {

        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler: TestScheduler!
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
                identifiers = [CBUUID(string: "aabb")]
            }
            describe("discover") {
                var characteristicsDiscoverObservable: ScheduledObservable<[Characteristic]>!
                var discoverCharacteristicsMethodObserver: TestableObserver<([CBUUID]?, RxServiceType)>!
                beforeEach {
                    fakePeripheral.discoverCharacteristicsTO = testScheduler.createObserver(([CBUUID]?, RxServiceType).self)
                    discoverCharacteristicsMethodObserver = fakePeripheral.discoverCharacteristicsTO
                    characteristicsDiscoverObservable = testScheduler.scheduleObservable {
                        return peripheral.discoverCharacteristics(identifiers, for: service)
                    }
                }
                context("before subscribe") {
                    it("should not be performed ") {
                        expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe") {
                    context("on success result") {
                        var fakeCharacteristics: [FakeCharacteristic]!
                        beforeEach {
                            fakeCharacteristics = [FakeCharacteristic(service: fakeService)]
                            let event: Event<(RxServiceType, Error?)> = Event.next(fakeService as RxServiceType, nil)
                            let service: [Recorded<Event<(RxServiceType, Error?)>>] = [Recorded(time: eventTime, value: event)]
                            fakePeripheral.rx_didDiscoverCharacteristicsForService = testScheduler.createHotObservable(service).asObservable()
                            testScheduler.advanceTo(eventTime - 1)
                            fakeService.characteristics = fakeCharacteristics.map { $0 as RxCharacteristicType }
                            testScheduler.advanceTo(250)
                        }

                        it("should discover") {
                            expect(discoverCharacteristicsMethodObserver.events.count).to(equal(1))
                        }
                        it("should discover with proper uuids") {
                            expect(discoverCharacteristicsMethodObserver.events[0].value.element!.0).to(equal(identifiers))
                        }
                        it("should discover characteristic  for proper service") {
                            expect(discoverCharacteristicsMethodObserver.events[0].value.element!.1 == fakeService as RxServiceType).to(beTrue())
                        }
                        describe("discovered characteristic") {
                            var characteristicsDiscovered: [Characteristic]?

                            beforeEach {
                                if let c = characteristicsDiscoverObservable.events.first?.value.element {
                                    characteristicsDiscovered = c
                                }
                            }
                            it("should not be nil") {
                                expect(characteristicsDiscovered).toNot(beNil())
                            }
                            it("should be the same as given to peripheral") {
                                expect(characteristicsDiscovered!.map { $0.characteristic } == fakeService.characteristics!).to(beTrue())
                            }
                        }
                    }
                    context("on failure") {
                        beforeEach {
                            let tuple: (RxServiceType, Error?) = (fakeService as RxServiceType, NSError(domain: "ERROR", code: 200, userInfo: nil))
                            let event: Event<(RxServiceType, Error?)> = .next(tuple)
                            let service: [Recorded<Event<(RxServiceType, Error?)>>] = [Recorded(time: eventTime, value: event)]
                            fakePeripheral.rx_didDiscoverCharacteristicsForService = testScheduler.createHotObservable(service).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return one event") {
                                expect(characteristicsDiscoverObservable.events.count).to(equal(1))
                            }
                            it("should return connection failed error") {
                                expectError(event: characteristicsDiscoverObservable.events[0].value, errorType: BluetoothError.characteristicsDiscoveryFailed(service, nil))
                            }
                        }
                    }
                }
                context("when bluetooth failed/unauthorized/restricted") {
                    var state: BluetoothState!
                    var error: BluetoothError!
                    //statesWithErrors are bluetooth state errors: unknown, unauthorized, unsupported, poweredOff, unknown
                    for stateWithError in statesWithErrors {
                        beforeEach {
                            state = stateWithError.0
                            error = stateWithError.1
                        }
                        context("before subscribe") {
                            it("should not be performed") {
                                expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(characteristicsDiscoverObservable.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicsDiscoverObservable.events[0].value, errorType: error)
                                }
                            }
                            context("when wrong state after calling") {
                                beforeEach {
                                    fakeCentralManager.state = .poweredOn
                                    let scans: [Recorded<Event<BluetoothState>>] = [Recorded(time: errorTime, value: .next(state))]
                                    fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                    testScheduler.advanceTo(250)
                                }
                                it("should call connect on central manager") {
                                    expect(discoverCharacteristicsMethodObserver.events.count).to(equal(1))
                                }
                                it("should get at least one event") {
                                    expect(characteristicsDiscoverObservable.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicsDiscoverObservable.events[0].value, errorType: error)
                                }
                            }
                        }
                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not be performed ") {
                            expect(discoverCharacteristicsMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe") {
                        context("when disconnected on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicsDiscoverObservable.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicsDiscoverObservable.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                        context("when disconnect after calling") {
                            beforeEach {
                                fakeCentralManager.state = .poweredOn
                                fakePeripheral.state = .connected
                                let event: Event<(RxPeripheralType, Error?)> = Event.next(fakePeripheral as RxPeripheralType, nil)
                                let scans: [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: errorTime, value: event)]
                                fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("should call discover characteristics method") {
                                expect(discoverCharacteristicsMethodObserver.events.count).to(equal(1))
                            }
                            context("getting wrong state in the middle of discover") {
                                it("should get event error") {
                                    expect(characteristicsDiscoverObservable.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicsDiscoverObservable.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                                }
                            }
                        }
                    }
                }
            }

            describe("writing to characteristic") {

                var data: Data!
                let writeType: CBCharacteristicWriteType = CBCharacteristicWriteType.withResponse
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var writeValueForCharacteristicMethodObserver: TestableObserver<(Data, RxCharacteristicType, CBCharacteristicWriteType)>!

                beforeEach {
                    fakePeripheral.writeValueForCharacteristicTypeTO = testScheduler.createObserver((Data, RxCharacteristicType, CBCharacteristicWriteType).self)
                    writeValueForCharacteristicMethodObserver = fakePeripheral.writeValueForCharacteristicTypeTO
                    data = "A".data(using: String.Encoding.utf8)
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.writeValue(data, for: characteristic, type: writeType)
                    }
                }
                context("before subscribe") {
                    it("should not be performed") {
                        expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe") {
                    context("on success") {
                        beforeEach {
                            let disconnect:
                            [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: errorTime, value: .next(fakePeripheral as RxPeripheralType, nil))]
                            fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(disconnect).asObservable()

                            let write: [Recorded<Event<(RxCharacteristicType, Error?)>>] = [Recorded(time: eventTime, value: .next(fakeCharacteristic as RxCharacteristicType, nil))]
                            fakePeripheral.rx_didWriteValueForCharacteristic = testScheduler.createHotObservable(write).asObservable()
                            testScheduler.advanceTo(250)
                        }

                        it("should call write on peripheral") {
                            expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(1))
                        }
                        it("should write with proper data") {
                            expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.0).to(equal(data))
                        }
                        it("should write to proper characteristic") {
                            expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic).to(beTrue())
                        }
                        it("should write with proper write type") {
                            expect(writeValueForCharacteristicMethodObserver.events[0].value.element!.2 == writeType).to(beTrue())

                        }

                        describe("characteristic written to") {
                            var characteristicWrittenTo: Characteristic?

                            beforeEach {
                                if let c = characteristicObserver.events.first?.value.element {
                                    characteristicWrittenTo = c
                                }
                            }
                            it("should not be nil") {
                                expect(characteristicWrittenTo).toNot(beNil())
                            }
                            it("should be same as given to peripheral") {
                                expect(characteristicWrittenTo!.characteristic == fakeCharacteristic).to(beTrue())
                            }
                        }
                    }
                    context("on fail") {
                        beforeEach {
                            let tuple: (RxCharacteristicType, Error?) = (fakeCharacteristic as RxCharacteristicType, NSError(domain: "ERROR", code: 200, userInfo: nil))
                            let write: [Recorded<Event<(RxCharacteristicType, Error?)>>] = [Recorded(time: eventTime, value: .next(tuple))]
                            fakePeripheral.rx_didWriteValueForCharacteristic = testScheduler.createHotObservable(write).asObservable()
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return one event") {
                                expect(characteristicObserver.events.count).to(equal(1))
                            }
                            it("should return connection failed error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.characteristicWriteFailed(characteristic, nil))
                            }
                        }
                    }
                }

                context("when bluetooth failed/unauthorized/restricted") {
                    var state: BluetoothState!
                    var error: BluetoothError!
                    for stateWithError in statesWithErrors {
                        beforeEach {
                            state = stateWithError.0
                            error = stateWithError.1
                        }
                        context("before subscribe") {
                            it("should not be performed") {
                                expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                            context("when wrong state after calling") {
                                beforeEach {
                                    fakeCentralManager.state = .poweredOn
                                    let scans: [Recorded<Event<BluetoothState>>] = [Recorded(time: 240, value: .next(state))]
                                    fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                    testScheduler.advanceTo(250)
                                }
                                it("should call connect on central manager") {
                                    expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(1))
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                        }

                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not be performed") {
                            expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe") {
                        context("when disconnect on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get at least one event") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                        context("when disconnect after calling") {
                            beforeEach {
                                //State is good on start.
                                fakeCentralManager.state = .poweredOn
                                fakePeripheral.state = .connected
                                //Different types of errors ::
                                let event: Event<(RxPeripheralType, Error?)> = Event.next(fakePeripheral as RxPeripheralType, nil)
                                let scans: [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: 240, value: event)]
                                fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("should call discover services") {
                                expect(writeValueForCharacteristicMethodObserver.events.count).to(equal(1))
                            }

                            it("should get at least one event") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }

            describe("reading from characteristic") {
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var readValueForCharacteristicMethodObserver: TestableObserver<(RxCharacteristicType)>!

                beforeEach {
                    fakePeripheral.readValueForCharacteristicTO = testScheduler.createObserver(RxCharacteristicType.self)
                    readValueForCharacteristicMethodObserver = fakePeripheral.readValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.readValue(for: characteristic)
                    }
                }
                context("before subscribe") {
                    it("should not be performed") {
                        expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with success read") {
                    context("on success") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateValueForCharacteristic = .just((fakeCharacteristic, nil))
                            testScheduler.advanceTo(250)
                        }

                        it("should call read") {
                            expect(readValueForCharacteristicMethodObserver.events.count).to(equal(1))
                        }
                        it("should read proper characteristic") {
                            expect(readValueForCharacteristicMethodObserver.events[0].value.element! == fakeCharacteristic).to(beTrue())
                        }

                        describe("read characteristic") {
                            var characteristicToRead: Characteristic?
                            beforeEach {
                                if let c = characteristicObserver.events.first?.value.element {
                                    characteristicToRead = c
                                }
                            }
                            it("should not be nil") {
                                expect(characteristicToRead).toNot(beNil())
                            }
                            it("should return proper characteristic") {
                                expect(characteristicToRead!.characteristic == fakeCharacteristic).to(beTrue())
                            }
                        }
                    }
                    context("on fail") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateValueForCharacteristic = .just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return event") {
                                expect(characteristicObserver.events.count).to(equal(1))
                            }
                            it("Should return coneection failed error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.characteristicReadFailed(characteristic, nil))
                            }
                        }
                    }
                }
                context("when bluetooth failed/unauthorized/restricted") {
                    var state: BluetoothState!
                    var error: BluetoothError!
                    for stateWithError in statesWithErrors {
                        beforeEach {
                            state = stateWithError.0
                            error = stateWithError.1
                        }

                        context("before subscribe") {
                            it("should not be performed") {
                                expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                            context("when wrong state after calling ") {
                                beforeEach {
                                    fakeCentralManager.state = .poweredOn
                                    let scans: [Recorded<Event<BluetoothState>>] = [Recorded(time: 240, value: .next(state))]
                                    fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                    testScheduler.advanceTo(250)
                                }
                                it("should call connect on central manager") {
                                    expect(readValueForCharacteristicMethodObserver.events.count).to(equal(1))
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                        }
                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(readValueForCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe") {
                        context("when wrong state on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                        context("when wrong state after calling function") {
                            beforeEach {
                                fakeCentralManager.state = .poweredOn
                                fakePeripheral.state = .connected
                                let event: Event<(RxPeripheralType, Error?)> = Event.next(fakePeripheral as RxPeripheralType, nil)
                                let scans: [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: 240, value: event)]
                                fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("should call discover services") {
                                expect(readValueForCharacteristicMethodObserver.events.count).to(equal(1))
                            }
                            context("getting wrong state in the middle of discover") {
                                beforeEach {
                                    fakeCentralManager.rx_didDisconnectPeripheral = .just((fakePeripheral, nil))
                                }
                                it("should get at least one event") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                                }
                            }
                        }
                    }
                }
            }
            describe("set notify on characteristic") {

                var characteristicObserver: ScheduledObservable<Characteristic>!
                var setNotifyCharacteristicMethodObserver: TestableObserver<(Bool, RxCharacteristicType)>!
                beforeEach {
                    fakePeripheral.setNotifyValueForCharacteristicTO = testScheduler.createObserver((Bool, RxCharacteristicType).self)
                    setNotifyCharacteristicMethodObserver = fakePeripheral.setNotifyValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.setNotifyValue(true, for: characteristic)
                    }
                }

                context("before subscribe") {
                    it("should not be performed ") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe") {
                    context("on success") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = .just((fakeCharacteristic, nil))
                            testScheduler.advanceTo(250)
                        }
                        it("should call read") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                        }
                        it("should read proper characteristic") {
                            expect(setNotifyCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic).to(beTrue())
                        }
                        describe("characteristic to read") {
                            var characteristicToRead: Characteristic?
                            beforeEach {
                                if let c = characteristicObserver.events.first?.value.element {
                                    characteristicToRead = c
                                }
                            }
                            it("should not be nil") {
                                expect(characteristicToRead).toNot(beNil())
                            }
                            it("should be same as given to peripheral") {
                                expect(characteristicToRead!.characteristic == fakeCharacteristic).to(beTrue())
                            }
                        }
                    }
                    context("on fail") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = .just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return one event") {
                                expect(characteristicObserver.events.count).to(equal(1))
                            }
                            it("Should return coneection failed error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.characteristicNotifyChangeFailed(characteristic, nil))
                            }
                        }
                    }
                }
                context("when bluetooth failed/unauthorized/restricted") {
                    var state: BluetoothState!
                    var error: BluetoothError!
                    for stateWithError in statesWithErrors {
                        beforeEach {
                            state = stateWithError.0
                            error = stateWithError.1
                        }

                        context("before subscribe") {
                            it("should not be performed") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }

                            context("when wrong state after calling") {
                                beforeEach {
                                    fakeCentralManager.state = .poweredOn
                                    let scans: [Recorded<Event<BluetoothState>>] = [Recorded(time: 240, value: .next(state))]
                                    fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                    testScheduler.advanceTo(250)
                                }
                                it("should call set notify on central manager") {
                                    expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                                }
                                it("should get at least one event") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                        }

                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not be performed") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }

                    context("after subscribe") {
                        context("when disconnect on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                        context("when disconnect after calling") {
                            beforeEach {
                                fakeCentralManager.state = .poweredOn
                                fakePeripheral.state = .connected
                                let event: Event<(RxPeripheralType, Error?)> = Event.next(fakePeripheral as RxPeripheralType, nil)
                                let scans: [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: 240, value: event)]
                                fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call discover services") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                    }

                }
            }
            describe("monitor characteristic updates") {
                var characteristicObserver: ScheduledObservable<Characteristic>!
                var setNotifyCharacteristicMethodObserver: TestableObserver<(Bool, RxCharacteristicType)>!
                beforeEach {
                    fakePeripheral.setNotifyValueForCharacteristicTO = testScheduler.createObserver((Bool, RxCharacteristicType).self)
                    setNotifyCharacteristicMethodObserver = fakePeripheral.setNotifyValueForCharacteristicTO
                    characteristicObserver = testScheduler.scheduleObservable {
                        return peripheral.setNotifyValue(true, for: characteristic)
                    }
                }

                context("before subscribe") {
                    it("should not be performed") {
                        expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe") {
                    context("on success") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = .just((fakeCharacteristic, nil))
                            testScheduler.advanceTo(250)
                        }
                        it("should call read") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                        }
                        it("should read proper characteristic") {
                            expect(setNotifyCharacteristicMethodObserver.events[0].value.element!.1 == fakeCharacteristic).to(beTrue())
                        }

                        describe("read characteristic") {
                            var characteristicToRead: Characteristic?

                            beforeEach {
                                if let c = characteristicObserver.events.first?.value.element {
                                    characteristicToRead = c
                                }
                            }
                            it("should not be nil") {
                                expect(characteristicToRead).toNot(beNil())
                            }
                            it("should return proper characteristic") {
                                expect(characteristicToRead!.characteristic == fakeCharacteristic).to(beTrue())
                            }
                        }
                    }
                    context("on fail") {
                        beforeEach {
                            fakePeripheral.rx_didUpdateNotificationStateForCharacteristic = .just((characteristic.characteristic, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return event") {
                                expect(characteristicObserver.events.count).to(equal(1))
                            }
                            it("Should return coneection failed error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.characteristicNotifyChangeFailed(characteristic, nil))
                            }
                        }
                    }
                }
                for stateWithError in statesWithErrors {
                context("when bluetooth failed/unauthorized/restricted") {
                    var state: BluetoothState!
                    var error: BluetoothError!
                        beforeEach {
                            state = stateWithError.0
                            error = stateWithError.1
                        }

                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }

                            context("when wrong state after calling") {
                                beforeEach {
                                    fakeCentralManager.state = .poweredOn
                                    let scans: [Recorded<Event<BluetoothState>>] = [Recorded(time: 240, value: .next(state))]
                                    fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                    testScheduler.advanceTo(250)
                                }
                                it("Should call monitor on central manager") {
                                    expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                                }
                                it("should get event") {
                                    expect(characteristicObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: characteristicObserver.events[0].value, errorType: error)
                                }
                            }
                        }
                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe") {
                        context("when disconnect on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                        context("when disconnect after calling") {
                            beforeEach {
                                fakeCentralManager.state = .poweredOn
                                fakePeripheral.state = .connected
                                let event: Event<(RxPeripheralType, Error?)> = Event.next(fakePeripheral as RxPeripheralType, nil)
                                let scans: [Recorded<Event<(RxPeripheralType, Error?)>>] = [Recorded(time: 240, value: event)]
                                fakeCentralManager.rx_didDisconnectPeripheral = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("Should call discover services") {
                                expect(setNotifyCharacteristicMethodObserver.events.count).to(equal(1))
                            }
                            it("should get event error") {
                                expect(characteristicObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: characteristicObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }
        }
    }
}
