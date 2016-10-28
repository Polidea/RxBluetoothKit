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


class PeripheralServicesSpec: QuickSpec {

    override func spec() {

        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler: TestScheduler!
        var fakePeripheral: FakePeripheral!
        var peripheral: Peripheral!
        var fakeService: FakeService!

        let statesWithErrors = BluetoothError.invalidStateErrors

        beforeEach {
            testScheduler = TestScheduler(initialClock: 0)
            fakePeripheral = FakePeripheral()
            fakeCentralManager = FakeCentralManager()
            manager = BluetoothManager(centralManager: fakeCentralManager)
            peripheral = Peripheral(manager: manager, peripheral: fakePeripheral)
            fakeService = FakeService()
        }

        describe("services") {

            var servicesObserver: ScheduledObservable<[Service]>!
            var cbuuids: [CBUUID]!

            beforeEach {
                cbuuids = [CBUUID(string: "bbaa")]
            }

            describe("discover") {
                var discoverServicesMethodObserver: TestableObserver<[CBUUID]?>!

                beforeEach {
                    fakePeripheral.discoverServicesTO = testScheduler.createObserver(([CBUUID]?).self)
                    discoverServicesMethodObserver = fakePeripheral.discoverServicesTO
                    servicesObserver = testScheduler.scheduleObservable {
                        peripheral.discoverServices(cbuuids)
                    }
                }
                context("before subscribe") {
                    it("should not call discover before subscribe") {
                        expect(discoverServicesMethodObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe ") {
                    context("on success result") {
                        beforeEach {
                            let servicesArray: [RxServiceType]? = [fakeService]
                            let event = Event<([RxServiceType]?, Error?)>.next(servicesArray, nil)
                            let discoveredServices: [Recorded<Event<([RxServiceType]?, Error?)>>] = [Recorded(time: 240,
                                value: event)]
                            fakePeripheral.rx_didDiscoverServices = testScheduler.createHotObservable(discoveredServices).asObservable()
                            testScheduler.advanceTo(230)
                            fakePeripheral.services = [fakeService]
                            testScheduler.advanceTo(250)
                        }
                        
                        it("should discover") {
                            expect(discoverServicesMethodObserver.events.count).to(equal(1))
                        }
                        
                        it("should discover with proper uuids") {
                            expect(discoverServicesMethodObserver.events[0].value.element!).to(equal(cbuuids))
                        }
                        describe("service") {
                            var servicesDiscovered: [Service]?
                            
                            beforeEach {
                                if let s = servicesObserver.events.first?.value.element {
                                    servicesDiscovered = s
                                }
                            }
                            it("should not be nil") {
                                expect(servicesDiscovered).toNot(beNil())
                            }
                            it("should be same as given to central manager") {
                                expect(servicesDiscovered!.map { $0.service } == [fakeService]).to(beTrue())
                            }
                        }
                    }
                    context("on failure") {
                        beforeEach {
                            fakePeripheral.rx_didDiscoverServices = .just((nil, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return event") {
                                expect(servicesObserver.events.count).to(equal(1))
                            }
                            it("Should return coneection failed error") {
                                expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.servicesDiscoveryFailed(peripheral, nil))
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
                                expect(discoverServicesMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event") {
                                    expect(servicesObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: servicesObserver.events[0].value, errorType: error)
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
                                    expect(discoverServicesMethodObserver.events.count).to(equal(1))
                                }
                                it("should get event error") {
                                    expect(servicesObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: servicesObserver.events[0].value, errorType: error)
                                }
                            }
                        }
                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not be performed") {
                            expect(discoverServicesMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("after subscribe") {
                        context("when disconnected on start") {
                            beforeEach {
                                fakePeripheral.state = .disconnected
                                testScheduler.advanceTo(250)
                            }
                            it("should get error") {
                                expect(servicesObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
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
                            it("should get event error") {
                                expect(servicesObserver.events.count).to(beGreaterThan(0))
                            }
                            it("should return proper error") {
                                expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                            }
                        }
                    }
                }
            }

            describe("discover included") {

                var service: Service!
                var discoverIncludedServicesMethodObserver: TestableObserver<([CBUUID]?, RxServiceType)>!
                beforeEach {
                    fakePeripheral.discoverIncludedServicesTO = testScheduler.createObserver(([CBUUID]?, RxServiceType).self)
                    discoverIncludedServicesMethodObserver = fakePeripheral.discoverIncludedServicesTO
                    service = Service(peripheral: peripheral, service: fakeService)
                    servicesObserver = testScheduler.scheduleObservable {
                        peripheral.discoverIncludedServices(cbuuids, for: service)
                    }
                }
                context("before subscribe") {
                    it("should not be performed") {
                        expect(servicesObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe") {
                    context("on success") {
                        var includedServices: [FakeService]!
                        let eventTime: Int = 230
                        beforeEach {
                            includedServices = [FakeService()]
                            let event: Event<(RxServiceType, Error?)> = Event.next(fakeService as RxServiceType, nil)
                            let services: [Recorded<Event<(RxServiceType, Error?)>>] = [Recorded(time: eventTime, value: event)]
                            fakePeripheral.rx_didDiscoverIncludedServicesForService = testScheduler.createHotObservable(services).asObservable()
                            testScheduler.advanceTo(eventTime - 1)
                            fakeService.includedServices = includedServices.map { $0 as RxServiceType }
                            testScheduler.advanceTo(250)
                        }
                        it("should call discover") {
                            expect(discoverIncludedServicesMethodObserver.events.count).to(equal(1))
                        }
                        it("should discover with proper uuids") {
                            expect(discoverIncludedServicesMethodObserver.events[0].value.element!.0).to(equal(cbuuids))
                        }
                        it("should discover included with proper service") {
                            expect(discoverIncludedServicesMethodObserver.events[0].value.element!.1 == service.service).to(beTrue())
                        }
                        describe("discovered service") {
                            var servicesDiscovered: [Service]?
                            
                            beforeEach {
                                if let s = servicesObserver.events.first?.value.element {
                                    servicesDiscovered = s
                                }
                            }
                            it("should not be nil") {
                                expect(servicesDiscovered).toNot(beNil())
                            }
                            it("should return proper service") {
                                _ = expect(servicesDiscovered!.map { $0.service } == includedServices)
                            }
                        }
                    }
                    context("on failure") {
                        beforeEach {
                            fakePeripheral.rx_didDiscoverIncludedServicesForService = .just((fakeService, NSError(domain: "ERROR", code: 200, userInfo: nil)))
                            testScheduler.advanceTo(250)
                        }
                        describe("error returned") {
                            it("should return event") {
                                expect(servicesObserver.events.count).to(equal(1))
                            }
                            it("Should return services discovery failed error") {
                                expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.includedServicesDiscoveryFailed(peripheral, nil))
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
                                expect(discoverIncludedServicesMethodObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe") {
                            context("when wrong state on start") {
                                beforeEach {
                                    fakeCentralManager.rx_didUpdateState = .just(state)
                                    testScheduler.advanceTo(250)
                                }
                                it("should get event error") {
                                    expect(servicesObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: servicesObserver.events[0].value, errorType: error)
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
                                    expect(discoverIncludedServicesMethodObserver.events.count).to(equal(1))
                                }
                                it("should get event error") {
                                    expect(servicesObserver.events.count).to(beGreaterThan(0))
                                }
                                it("should return proper error") {
                                    expectError(event: servicesObserver.events[0].value, errorType: error)
                                }
                            }
                        }
                    }
                }
                context("when device disconnects at some time") {
                    context("before subscribe") {
                        it("should not call before subscribe") {
                            expect(discoverIncludedServicesMethodObserver.events.count).to(equal(0))
                        }
                    }
                    context("when disconnected on start") {
                        beforeEach {
                            fakePeripheral.state = .disconnected
                            testScheduler.advanceTo(250)
                        }
                        it("should get event error") {
                            expect(servicesObserver.events.count).to(beGreaterThan(0))
                        }
                        it("should return proper error") {
                            expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
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
                        it("should call discover services") {
                            expect(discoverIncludedServicesMethodObserver.events.count).to(equal(1))
                        }
                        it("should get event error") {
                            expect(servicesObserver.events.count).to(beGreaterThan(0))
                        }
                        it("should return proper error") {
                            expectError(event: servicesObserver.events[0].value, errorType: BluetoothError.peripheralDisconnected(peripheral, nil))
                        }
                    }
                }
            }
        }
    }
}
