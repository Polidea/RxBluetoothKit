//
//  BluetoothManagerSpec.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 24.02.2016.
//

import Quick
import Nimble
import CoreBluetooth
@testable
import RxBluetoothKit
import RxTests
import RxSwift

//TODO: Add testable import

class BluetoothManagerSpec : QuickSpec {
    override func spec() {
        
        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler : TestScheduler!
        var fakePeripheral: FakePeripheral!
        let statesWithErrors = BluetoothError.invalidStateErrors
        
        var nextTime: Int!
        var errorTime: Int!
        beforeEach {
            fakePeripheral = FakePeripheral()
            fakeCentralManager = FakeCentralManager()
            manager = BluetoothManager(centralManager: fakeCentralManager)
            testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
            nextTime = 230
            errorTime = 240
        }

        describe("retrieving peripherals") {
            
            var peripheralsObserver : ScheduledObservable<[Peripheral]>!
            context("via identifiers") {
                var uuids: [NSUUID]!
                var retrieveWithIdentifiersCallObserver : TestableObserver<[NSUUID]>!
                
                beforeEach {
                    uuids = [NSUUID(), NSUUID()]
                    fakeCentralManager.retrievePeripheralsWithIdentifiersTO = testScheduler.createObserver([NSUUID])
                    retrieveWithIdentifiersCallObserver = fakeCentralManager.retrievePeripheralsWithIdentifiersTO
                    peripheralsObserver = testScheduler.scheduleObservable { manager.retrievePeripheralsWithIdentifiers(uuids) }
                    fakeCentralManager.state = .PoweredOn
                }
                context("before subscription") {
                    it("should not call retrieve method") {
                        expect(retrieveWithIdentifiersCallObserver.events.count).to(equal(0))
                    }
                }
                context("after subscription") {
                    beforeEach {
                        let peripherals: [Recorded<Event<[RxPeripheralType]>>] = [Recorded(time: nextTime, event: .Next([fakePeripheral]))]
                        fakeCentralManager.retrievePeripheralsWithIdentifiersResult = testScheduler.createHotObservable(peripherals).asObservable()
                        testScheduler.advanceTo(250)
                    }
                    it("should call retrieve method on central manager") {
                        expect(retrieveWithIdentifiersCallObserver.events.count).to(equal(1))
                    }
                    it("should call it with proper identifiers") {
                        expect(retrieveWithIdentifiersCallObserver.events[0].value.element! == uuids)
                    }
                    it("should receive event in return") {
                        expect(peripheralsObserver.events.count).to(equal(1))
                    }
                    it("should retrieve next with peripherals table") {
                        expect(peripheralsObserver.events[0].value.element).toNot(beNil())
                    }
                    it("should retrieve next with exactly one peripheral in table") {
                        expect(peripheralsObserver.events[0].value.element!.count).to(equal(1))
                    }
                    it("should get proper peripheral") {
                        expect(peripheralsObserver.events[0].value.element![0].peripheral == fakePeripheral)
                    }
                }
                describe("error propagation in wrong bluetooth state") {
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
                                expect(retrieveWithIdentifiersCallObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.state = state
                                testScheduler.advanceTo(250)
                            }
                            it("should get error") {
                                expect(peripheralsObserver.events.count > 0)
                            }
                            it("should get proper error") {
                                expectError(peripheralsObserver.events[0].value, errorType: error)
                            }
                        }
                        context("after subscribe and getting wrong state after function is called") {
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: errorTime, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("should call on central manager") {
                                expect(retrieveWithIdentifiersCallObserver.events.count == 1)
                            }

                            it("should get error") {
                                expect(peripheralsObserver.events.count > 0)
                            }
                            it("should get proper error") {
                                expectError(peripheralsObserver.events[0].value, errorType: error)
                            }
                        }
                    }
                }
            }
            context("via services uuids") {
                var retrieveWithServicesCallObserver : TestableObserver<[CBUUID]>!
                var cbuuids: [CBUUID]!
                beforeEach {
                    cbuuids = [CBUUID()]
                    fakeCentralManager.retrieveConnectedPeripheralsWithServicesResult = Observable.just([fakePeripheral])
                    fakeCentralManager.retrieveConnectedPeripheralsWithServicesTO = testScheduler.createObserver([CBUUID])
                    retrieveWithServicesCallObserver = fakeCentralManager.retrieveConnectedPeripheralsWithServicesTO
                    peripheralsObserver = testScheduler.scheduleObservable { manager.retrieveConnectedPeripheralsWithServices(cbuuids)}
                    fakeCentralManager.state = .PoweredOn
                }
                context("before subscription") {
                    it("should not call retrieve method") {
                        expect(retrieveWithServicesCallObserver.events.count).to(equal(0))
                    }
                }
                context("after subscription") {
                    beforeEach {
                        fakeCentralManager.retrievePeripheralsWithIdentifiersResult = Observable.just([fakePeripheral])
                        testScheduler.advanceTo(250)
                    }
                    it("should call retrieve method on central manager") {
                        expect(retrieveWithServicesCallObserver.events.count).to(equal(1))
                    }
                    it("should call with proper identifiers") {
                        expect(retrieveWithServicesCallObserver.events[0].value.element! == cbuuids)
                    }
                    it("should receive event") {
                        expect(peripheralsObserver.events.count).to(equal(1))
                    }
                    it("should retrieve peripherals table") {
                        expect(peripheralsObserver.events[0].value.element).toNot(beNil())
                    }
                    it("should retrieve exactly one peripheral in table") {
                        expect(peripheralsObserver.events[0].value.element!.count).to(equal(1))
                    }
                    it("should retrieve given peripheral") {
                        expect(peripheralsObserver.events[0].value.element![0].peripheral == fakePeripheral)
                    }
                }
                describe("error propagation") {
                    var state: CBCentralManagerState!
                    var error: BluetoothError!
                    for i in statesWithErrors {
                        beforeEach {
                            let (s, e) = i
                            state = s
                            error = e
                        }
                        beforeEach {
                        }
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(retrieveWithServicesCallObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                fakeCentralManager.state = state
                                testScheduler.advanceTo(250)
                            }
                            it("should get error") {
                                expect(peripheralsObserver.events.count > 0)
                            }
                            it("should return p error") {
                                expectError(peripheralsObserver.events[0].value, errorType: error)
                            }
                        }
                        context("after subscribe and getting wrong state after function is called") {
                            
                            beforeEach {
                                fakeCentralManager.state = .PoweredOn
                                let scans: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: 240, event: .Next(state))]
                                fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(scans).asObservable()
                                testScheduler.advanceTo(250)
                            }
                            it("should call method on central manager once") {
                                expect(retrieveWithServicesCallObserver.events.count == 1)
                            }
                            it("should get two events - peripheral and error") {
                                expect(peripheralsObserver.events.count == 2)
                            }
                            it("should return proper error") {
                                expectError(peripheralsObserver.events[1].value, errorType: error)
                            }
                        }
                    }
                }
            }
        }
        
        describe("interaction with device") {
            
            var peripheral: Peripheral!
            beforeEach {
                peripheral = Peripheral(manager: manager, peripheral: fakePeripheral)

            }

            describe("Error propagation") {

                var state: CBCentralManagerState!
                var error: BluetoothError!
                
                var peripheralObserver: ScheduledObservable<Peripheral>!
                var cancelConnectionObserver: TestableObserver<RxPeripheralType>!

                context("connecting while bluetooth dissalows connection") {
                    var connectObserver: TestableObserver<(RxPeripheralType, [String: AnyObject]?)>!
                    for i in statesWithErrors {
                        beforeEach {
                            fakeCentralManager.connectPeripheralOptionsTO = testScheduler.createObserver((RxPeripheralType, [String: AnyObject]?))
                            connectObserver = fakeCentralManager.connectPeripheralOptionsTO
                            peripheralObserver = testScheduler.scheduleObservable {
                                manager.connectToPeripheral(peripheral)
                            }
                            let (s, e) = i
                            state = s
                            error = e
                            fakeCentralManager.state = state
                        }
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(connectObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                testScheduler.advanceTo(250)
                            }
                            it("should get event error") {
                                expect(peripheralObserver.events.count > 0)
                            }
                            it("should return proper error") {
                                expectError(peripheralObserver.events[0].value, errorType: error)
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
                                expect(connectObserver.events.count == 1)
                            }
                            
                            it("should get events") {
                                expect(peripheralObserver.events.count > 0)
                            }
                            it("should return proper error after peripheral") {
                                expectError(peripheralObserver.events[1].value, errorType: error)
                            }
                        }
                    }
                }
                
                context("disconnecting while bluetooth disallows") {
                    for i in statesWithErrors {
                        beforeEach {
                            fakeCentralManager.cancelPeripheralConnectionTO = testScheduler.createObserver(RxPeripheralType)
                            cancelConnectionObserver = fakeCentralManager.cancelPeripheralConnectionTO
                            peripheralObserver = testScheduler.scheduleObservable {
                                manager.cancelConnectionToPeripheral(peripheral)
                            }
                            let (s, e) = i
                            state = s
                            error = e
                            fakeCentralManager.state = state
                        }
                        context("before subscribe") {
                            it("should not call before subscribe") {
                                expect(cancelConnectionObserver.events.count).to(equal(0))
                            }
                        }
                        context("after subscribe and getting wrong state on start") {
                            beforeEach {
                                testScheduler.advanceTo(250)
                            }
                            it("should return proper error") {
                                expectError(peripheralObserver.events[0].value, errorType: error)
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
                                expect(cancelConnectionObserver.events.count == 1)
                            }
                            it("should return proper error") {
                                expectError(peripheralObserver.events[0].value, errorType: error)
                            }
                        }
                        
                    }
                }
            }
            
            describe("connecting to device with powered on BT ") {
                var connectionTime : Int!
                var peripheralObserver: ScheduledObservable<Peripheral>!
                var connectObserver: TestableObserver<(RxPeripheralType, [String: AnyObject]?)>!
                
                beforeEach {
                    fakeCentralManager.rx_didUpdateState = Observable.just(.PoweredOn)
                    fakeCentralManager.connectPeripheralOptionsTO = testScheduler.createObserver((RxPeripheralType, [String: AnyObject]?))
                    connectObserver = fakeCentralManager.connectPeripheralOptionsTO
                    peripheralObserver = testScheduler.scheduleObservable {
                        manager.connectToPeripheral(peripheral)
                    }
                    fakeCentralManager.state = .PoweredOn
                    fakePeripheral.state = .Disconnected
                    connectionTime = peripheralObserver.time.after.subscribeTime
                }
                context("before subscribe") {
                    it("should not call connect before subscribe") {
                        expect(connectObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with connection success") {
                    beforeEach {
                        testScheduler.scheduleAt(connectionTime, action: {fakePeripheral.state = CBPeripheralState.Connected})
                        fakeCentralManager.rx_didConnectPeripheral =
                            testScheduler.createHotObservable([Recorded(time: connectionTime, event: .Next(peripheral.peripheral))]).asObservable()
                        
                        testScheduler.advanceTo(connectionTime + 1)
                    }
                    
                    //Common to both success and fail end...
                    it("should call connect") {
                        expect(connectObserver.events.count).to(equal(1))
                    }
                    it("Should call connect to proper peripheral") {
                        let (peripheralToConnect, _) = connectObserver.events[0].value.element!
                        expect(peripheralToConnect == peripheral.peripheral)
                    }
                    
                    
                    describe("connected peripheral") {
                        var peripheralConnected: Peripheral?

                        beforeEach {
                            if let p = peripheralObserver.events.first?.value.element {
                                peripheralConnected = p
                            }
                        }
                        it("should return peripheral") {
                            expect(peripheralConnected).toNot(beNil())
                        }
                        it("should return peripheral to which we're trying to connect to") {
                            expect(peripheralConnected!.peripheral == peripheral.peripheral)
                        }

                    }
                }
                context("after subscribe with connection failed") {
                    beforeEach {
                        fakeCentralManager.rx_didConnectPeripheral =
                            testScheduler.createHotObservable([Recorded(time: connectionTime, event: .Next(peripheral.peripheral))]).asObservable()
                        fakeCentralManager.rx_didFailToConnectPeripheral = Observable.just((peripheral.peripheral, NSError(domain: "Error", code: 200, userInfo: nil)))
                        testScheduler.advanceTo(250)
                    }
                    
                    it("should call connect") {
                        expect(connectObserver.events.count).to(equal(1))
                    }
                    it("should call connect with proper peripheral") {
                        let (peripheralToConnect, _) = connectObserver.events[0].value.element!
                        expect(peripheralToConnect == peripheral.peripheral)
                    }
                    
                    describe("error returned") {
                        it("should return event") {
                            expect(peripheralObserver.events.count).to(beGreaterThan(0))
                        }
                        
                        it("Should return coneection failed error") {
                            expectError(peripheralObserver.events[0].value, errorType: BluetoothError.PeripheralConnectionFailed(peripheral, nil))
                        }
                    }
                }
            }
            describe("disconnecting from device with powered ON BT.") {
                var peripheralObserver: ScheduledObservable<Peripheral>!
                var disconnectObserver: TestableObserver<RxPeripheralType>!
                
                
                beforeEach {
                    fakeCentralManager.rx_didUpdateState = Observable.just(.PoweredOn)
                    fakeCentralManager.cancelPeripheralConnectionTO = testScheduler.createObserver(RxPeripheralType)
                    disconnectObserver = fakeCentralManager.cancelPeripheralConnectionTO
                    peripheralObserver = testScheduler.scheduleObservable {
                        manager.cancelConnectionToPeripheral(peripheral)
                    }
                    fakeCentralManager.state = .PoweredOn
                }
                context("Before subscribe") {
                    it("should not call disconnect before subscribe") {
                        expect(disconnectObserver.events.count).to(equal(0))
                    }
                }
                context("after subscribe with disconnection success") {
                    beforeEach {
                        fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((peripheral.peripheral, nil))
                        testScheduler.advanceTo(250)
                    }
                    it("should call disconnect with proper peripheral") {
                        expect(disconnectObserver.events.count).to(equal(1))
                        let peripheralToDisconnect = disconnectObserver.events[0].value.element!
                        expect(peripheralToDisconnect == peripheral.peripheral)
                    }
                    describe("disconnected peripheral") {
                        var peripheralDisconnected: Peripheral?
                        beforeEach {
                            if let p = peripheralObserver.events.first?.value.element {
                                peripheralDisconnected = p
                            }
                        }
                        it("should return peripheral") {
                            expect(peripheralDisconnected).toNot(beNil())
                        }
                        it("should return peripheral from which we're trying to disconnect") {
                            expect(peripheralDisconnected!.peripheral == peripheral.peripheral)
                        }
                    }
                }
                context("when peripheral is disconnected with an error (disconnection executed by system)") {
                    beforeEach {
                        fakeCentralManager.rx_didDisconnectPeripheral = Observable.just((peripheral.peripheral, NSError(domain: "error", code: 200, userInfo: nil)))
                        testScheduler.advanceTo(peripheralObserver.time.after.subscribeTime)
                    }
                    it("should call disconnect with proper peripheral") {
                        expect(disconnectObserver.events.count).to(equal(1))
                        let peripheralToDisconnect = disconnectObserver.events[0].value.element!
                        expect(peripheralToDisconnect == peripheral.peripheral)
                    }
                    it("Should return an peripheral event with completed stream") {
                        expect(peripheralObserver.events.count).to(equal(2))
                        expect(peripheralObserver.events[0].value.element == peripheral)
                        expect(peripheralObserver.events[1].value == Event.Completed)
                    }
                }
            }
        }
    }
}


