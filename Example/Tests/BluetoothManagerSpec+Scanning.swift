//
//  BluetoothScanningSpec.swift
//  RxBluetoothKit
//
//  Created by Kacper Harasim on 01.03.2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//
import Quick
import Nimble

import CoreBluetooth
import RxBluetoothKit
import RxTests
import RxSwift

class BluetoothManagerSpecScanning : QuickSpec {
    
    override func spec() {
        
        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler : TestScheduler!
        var fakePeripheral: FakePeripheral!
        
        beforeEach {
            fakePeripheral = FakePeripheral()
            fakeCentralManager = FakeCentralManager()
            manager = BluetoothManager(centralManager: fakeCentralManager)
            testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        }
        
        describe("scanning devices test") {
            var scanObservers : [ScheduledObservable<ScannedPeripheral>]!
            
            var scanCallObserver : TestableObserver<([CBUUID]?, [String:AnyObject]?)>!
            var stopScanCallObserver : TestableObserver<()>!
            
            beforeEach {
                scanCallObserver = testScheduler.createObserver(([CBUUID]?, [String:AnyObject]?))
                fakeCentralManager.scanForPeripheralsWithServicesTO = scanCallObserver
                
                stopScanCallObserver = testScheduler.createObserver(Void)
                fakeCentralManager.stopScanTO = stopScanCallObserver
                
                scanObservers = [testScheduler.scheduleObservable { manager.scanForPeripherals([]) }]
            }
            
            context("before scanning") {
                
                it("contains valid time for test scheduler") {
                    expect(testScheduler.clock).to(equal(0))
                }
                
                it("didn't call scan function for any observer") {
                    for observer in scanObservers {
                        expect(observer.events).to(beEmpty())
                    }
                }
            }
            
            for (cberror, bleerror) in  BluetoothError.invalidStateErrors {
                context("when bluetooth manager has state: \(bleerror) and user is subscribed for scanning") {
                    beforeEach {
                        fakeCentralManager.state = cberror
                        testScheduler.advanceTo(scanObservers[0].subscribeTime)
                    }
                    
                    it("should return only an error") {
                        expect(scanObservers[0].events.count).to(equal(1))
                        expectError(scanObservers[0].events[0].value, errorType: bleerror)
                    }
                }
                
                context("when bluetooth manager has state: \(bleerror)") {
                    let firstScanTime = 550
                    let errorPropagationTime = 600
                    
                    beforeEach {
                        fakeCentralManager.state = .PoweredOn
                        let errors : [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: errorPropagationTime, event: .Next(cberror))]
                        testScheduler.scheduleAt(errorPropagationTime - 1, action: {fakeCentralManager.state = cberror})
                        fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(errors).asObservable()
                        fakeCentralManager.rx_didDiscoverPeripheral = testScheduler.createHotObservable(
                            [Recorded(time: firstScanTime, event: .Next(FakePeripheral() as RxPeripheralType, [String:AnyObject](), NSNumber(double: 0)))]).asObservable()
                    }
                    
                    context("when first device is scanned") {
                        beforeEach {
                            testScheduler.advanceTo(firstScanTime)
                        }
                        
                        it ("it should find one scanned device") {
                            expect(scanObservers[0].events.count).to(equal(1))
                            expect(scanObservers[0].events[0].value.isStopEvent).to(beFalse())
                        }
                    }
                    
                    context("when error is propagated") {
                        beforeEach {
                            testScheduler.advanceTo(errorPropagationTime)
                        }
                        
                        it ("it should find one scanned device and emit error") {
                            expect(scanObservers[0].events.count).to(equal(2))
                            expect(scanObservers[0].events[0].value.isStopEvent).to(beFalse())
                            expectError(scanObservers[0].events[1].value, errorType: bleerror)
                        }
                    }
                }
            }
            
            context("when bluetooth manager is powered on and there are 3 devices to be scanned") {
                var recordsTime : [Int]!
                var recordsRSSI : [Double]!
                
                func expectRecordsFor(records: [Recorded<Event<ScannedPeripheral>>], rssis: [Double], file: String = __FILE__, line: UInt = __LINE__) {
                    expect(records.count, file: file, line: line).to(equal(rssis.count))
                    for (i, record) in records.enumerate() {
                        expect(record.value.isStopEvent).to(beFalse())
                        let args : ScannedPeripheral = record.value.element!
                        expect(args.RSSI).to(equal(rssis[i]))
                    }
                }
                
                beforeEach {
                    fakeCentralManager.state = .PoweredOn
                    var scans : [Recorded<Event<(RxPeripheralType, [String:AnyObject], NSNumber)>>] = []
                    
                    recordsRSSI = []
                    recordsTime = []
                    
                    for i in 0..<3 {
                        let time = 450 * (i+1)
                        let rssi = Double(i) * 10
                        recordsTime.append(time)
                        recordsRSSI.append(rssi)
                        scans.append(Recorded(time: time, event: .Next(FakePeripheral() as RxPeripheralType,
                            [String:AnyObject](),
                            NSNumber(double: rssi))))
                    }
                    
                    let scansObservable = testScheduler.createHotObservable(scans)
                    fakeCentralManager.rx_didDiscoverPeripheral = scansObservable.asObservable()
                }
                
                context("before user is subscribed for scanning") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[0].time.before.subscribeTime)
                    }
                    it("should not call scan function") {
                        expect(scanCallObserver.events.count).to(equal(0))
                    }
                }
                
                context("after first scanned device") {
                    beforeEach {
                        testScheduler.advanceTo(recordsTime[0])
                    }
                    it("should call scan function once") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }
                    it("should have only one scanned device registered") {
                        expectRecordsFor(scanObservers[0].events, rssis: [recordsRSSI[0]])
                    }
                }
                context("after all detected scanned devices") {
                    beforeEach {
                        testScheduler.advanceTo(recordsTime.last!)
                    }
                    it("should call scan function once") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }
                    it("should register all scanned devices detected before disposal and don't complete it's stream ") {
                        expectRecordsFor(scanObservers[0].events, rssis: [recordsRSSI[0], recordsRSSI[1]])
                    }
                }
                
                context("when there are two simultaneous users of bluetooth manager") {
                    
                    beforeEach {
                        let times = ObservableScheduleTimes(createTime: 150, subscribeTime: 600, disposeTime: 1400)
                        scanObservers.append(testScheduler.scheduleObservable(times, create: {manager.scanForPeripherals([])}))
                    }
                    
                    context("and only first user is subscribed and one peripheral was discovered") {
                        beforeEach {
                            testScheduler.advanceTo(recordsTime[0])
                        }
                        it("should call scan function once only") {
                            expect(scanCallObserver.events.count).to(equal(1))
                        }
                        it("should contain one event for first observer") {
                            expectRecordsFor(scanObservers[0].events, rssis: [recordsRSSI[0]])
                        }
                        it("shoudn't contain any event for second observer") {
                            expect(scanObservers[1].events).to(beEmpty())
                        }
                    }
                    
                    context("when two users are subscribed and two devices are discovered") {
                        beforeEach {
                            testScheduler.advanceTo(recordsTime[1])
                        }
                        it("should call scan function once only") {
                            expect(scanCallObserver.events.count).to(equal(1))
                        }
                        it("should emit two events for first user") {
                            expectRecordsFor(scanObservers[0].events, rssis: [recordsRSSI[0], recordsRSSI[1]])
                        }
                        it("should emit one event for second user") {
                            expectRecordsFor(scanObservers[1].events, rssis: [recordsRSSI[1]])
                        }
                    }
                    
                    context("when first user is unsubsribed and last scan is delivered") {
                        beforeEach {
                            testScheduler.advanceTo(recordsTime[2])
                        }
                        it("shoudn't call stop scan function") {
                            expect(stopScanCallObserver.events).to(beEmpty())
                        }
                        it("should emit two events for third user") {
                            expectRecordsFor(scanObservers[1].events, rssis: [recordsRSSI[1], recordsRSSI[2]])
                        }
                    }
                    
                    context("when all users are unsubscribed") {
                        beforeEach {
                            testScheduler.advanceTo(scanObservers[1].time.after.disposeTime)
                        }
                        it("shoud call stop scan function") {
                            expect(stopScanCallObserver.events.count).to(equal(1))
                        }
                    }
                }
            }
        }
    }
}