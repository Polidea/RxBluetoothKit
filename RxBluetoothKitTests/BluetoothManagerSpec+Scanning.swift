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

import CoreBluetooth
import RxBluetoothKit
import RxTests
import RxSwift

class BluetoothManagerScanningSpec: QuickSpec {

    override func spec() {

        var manager: BluetoothManager!
        var fakeCentralManager: FakeCentralManager!
        var testScheduler: TestScheduler!
        var fakePeripheral: FakePeripheral!

        beforeEach {
            fakePeripheral = FakePeripheral()
            fakeCentralManager = FakeCentralManager()
            testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
            manager = BluetoothManager(centralManager: fakeCentralManager, queueScheduler: testScheduler)
        }

        describe("scanning devices") {
            var scanObservers: [ScheduledObservable<ScannedPeripheral>]!

            var scanCallObserver: TestableObserver<([CBUUID]?, [String:AnyObject]?)>!
            var stopScanCallObserver: TestableObserver<()>!

            beforeEach {
                scanCallObserver = testScheduler.createObserver(([CBUUID]?, [String: AnyObject]?))
                fakeCentralManager.scanForPeripheralsWithServicesTO = scanCallObserver

                stopScanCallObserver = testScheduler.createObserver(Void)
                fakeCentralManager.stopScanTO = stopScanCallObserver

                scanObservers = []
            }

            // For every invalid bluetooth state:
            // .PoweredOff,
            // .Resetting,
            // .Unauthorized,
            // .Unknown,
            // .Unsupported
            for (cberror, bleerror) in BluetoothError.invalidStateErrors {
                context("when bluetooth manager has state: \(bleerror) and user is subscribed for scanning") {
                    beforeEach {
                        fakeCentralManager.state = cberror
                        scanObservers.append(testScheduler.scheduleObservable {manager.scanForPeripherals(nil)})
                        testScheduler.advanceTo(scanObservers[0].subscribeTime)
                    }

                    it("should return only an error") {
                        expect(scanObservers[0].events.count).to(equal(1))
                        expectError(scanObservers[0].events[0].value, errorType: bleerror)
                    }
                }

                context("when bluetooth changes state to: \(bleerror) during scanning of services") {
                    let firstScanTime = 550
                    let errorPropagationTime = 600

                    beforeEach {
                        fakeCentralManager.state = .PoweredOn
                        scanObservers.append(testScheduler.scheduleObservable {manager.scanForPeripherals(nil)})

                        let errors: [Recorded<Event<CBCentralManagerState>>] = [Recorded(time: errorPropagationTime, event: .Next(cberror))]
                        testScheduler.scheduleAt(errorPropagationTime - 1, action: { fakeCentralManager.state = cberror })

                        fakeCentralManager.rx_didUpdateState = testScheduler.createHotObservable(errors).asObservable()
                        fakeCentralManager.rx_didDiscoverPeripheral = testScheduler.createHotObservable(
                            [Recorded(time: firstScanTime, event: .Next(FakePeripheral() as RxPeripheralType,
                                                                        [String: AnyObject](),
                                                                        NSNumber(double: 0)))]).asObservable()
                    }

                    context("when first device is scanned") {
                        beforeEach {
                            testScheduler.advanceTo(firstScanTime)
                        }

                        it("should find one scanned device") {
                            expect(scanObservers[0].events.count).to(equal(1))
                            expect(scanObservers[0].events[0].value.isStopEvent).to(beFalse())
                        }
                    }

                    context("when error is propagated") {
                        beforeEach {
                            testScheduler.advanceTo(errorPropagationTime)
                        }

                        it("should find one scanned device and emit error") {
                            expect(scanObservers[0].events.count).to(equal(2))
                            expect(scanObservers[0].events[0].value.isStopEvent).to(beFalse())
                            expectError(scanObservers[0].events[1].value, errorType: bleerror)
                        }
                    }
                }
            }

            context("when bluetooth manager is powered on and there are 3 devices to be scanned") {
                func expectMatchPeripherals(fromRecords: [Recorded<Event<ScannedPeripheral>>],
                                            withRSSIs: [Double],
                                            inFile: String = #file,
                                            inLine: UInt = #line) {
                    expect(fromRecords.count, file: inFile, line: inLine).to(equal(withRSSIs.count))
                    for (i, record) in fromRecords.enumerate() {
                        expect(record.value.isStopEvent).to(beFalse())
                        let args: ScannedPeripheral = record.value.element!
                        expect(args.RSSI).to(equal(withRSSIs[i]))
                    }
                }

                var recordsTime: [Int]!
                var recordsRSSI: [Double]!

                beforeEach {
                    fakeCentralManager.state = .PoweredOn
                    scanObservers.append(testScheduler.scheduleObservable {manager.scanForPeripherals(nil)})
                    var scans: [Recorded<Event<(RxPeripheralType, [String:AnyObject], NSNumber)>>] = []

                    recordsRSSI = []
                    recordsTime = []

                    for i in 0 ..< 3 {
                        let time = 450 * (i + 1)
                        let rssi = Double(i) * 10
                        recordsTime.append(time)
                        recordsRSSI.append(rssi)
                        scans.append(Recorded(time: time, event: .Next(FakePeripheral() as RxPeripheralType,
                                [String: AnyObject](),
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
                        expectMatchPeripherals(scanObservers[0].events, withRSSIs: [recordsRSSI[0]])
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
                        expectMatchPeripherals(scanObservers[0].events, withRSSIs: [recordsRSSI[0], recordsRSSI[1]])
                    }
                }

                context("when there are two simultaneous users of bluetooth manager") {

                    beforeEach {
                        let times = ObservableScheduleTimes(createTime: 150, subscribeTime: 600, disposeTime: 1400)
                        scanObservers.append(testScheduler.scheduleObservable(times, create: { manager.scanForPeripherals(nil) }))
                    }

                    context("when only first user is subscribed and one peripheral was discovered") {
                        beforeEach {
                            testScheduler.advanceTo(recordsTime[0])
                        }
                        it("should call scan function once only") {
                            expect(scanCallObserver.events.count).to(equal(1))
                        }
                        it("should contain one event for first observer") {
                            expectMatchPeripherals(scanObservers[0].events, withRSSIs: [recordsRSSI[0]])
                        }
                        it("shouldn't contain any events for second observer") {
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
                            expectMatchPeripherals(scanObservers[0].events, withRSSIs: [recordsRSSI[0], recordsRSSI[1]])
                        }
                        it("should emit one event for second user") {
                            expectMatchPeripherals(scanObservers[1].events, withRSSIs: [recordsRSSI[1]])
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
                            expectMatchPeripherals(scanObservers[1].events, withRSSIs: [recordsRSSI[1], recordsRSSI[2]])
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

            context("when there are two users scanning for different UUIDs") {
                beforeEach {
                    let times = ObservableScheduleTimes(createTime: 100, subscribeTime: 300, disposeTime: 1000)
                    let times2 = ObservableScheduleTimes(createTime: 150, subscribeTime: 600, disposeTime: 1400)
                    scanObservers.append(testScheduler.scheduleObservable(times,
                        create: {manager.scanForPeripherals([CBUUID(string: "aaff"), CBUUID(string: "dfff")])}))
                    scanObservers.append(testScheduler.scheduleObservable(times2,
                        create: {manager.scanForPeripherals([CBUUID(string: "dfff")])}))
                }

                context("when first user subscribed") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[0].subscribeTime)
                    }
                    it("should call scan function once") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }
                    it("shouldn't call stop function") {
                        expect(stopScanCallObserver.events).to(beEmpty())
                    }
                }

                context("when second user subscribed") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[1].subscribeTime)
                    }
                    it("should call scan function once because first user didn't finish scanning") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }
                    it("shouldn't call stop function because first user didn't finish scanning") {
                        expect(stopScanCallObserver.events).to(beEmpty())
                    }
                }

                context("when first user finished scanning") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[0].disposeTime)
                    }
                    it("should call scan function twice because second user started scanning") {
                        expect(scanCallObserver.events.count).to(equal(2))
                    }
                    it("should call stop function for first scan") {
                        expect(stopScanCallObserver.events.count).to(equal(1))
                    }
                }

                context("when second user finished scanning") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[1].disposeTime)
                    }
                    it("should call scan function twice because second user started scanning") {
                        expect(scanCallObserver.events.count).to(equal(2))
                    }
                    it("should call stop function for both scans") {
                        expect(stopScanCallObserver.events.count).to(equal(2))
                    }
                }
            }

            context("when there are two users scanning where one is using existing scan") {
                typealias ScanType = (RxPeripheralType, [String:AnyObject], NSNumber)

                func createPeripheralEvents(events: (Int, [String], Int)... ) -> [Recorded<Event<ScanType>>] {
                    var records : [Recorded<Event<ScanType>>] = []
                    for event in events {
                        var advertisment = [String:AnyObject]()
                        advertisment[CBAdvertisementDataServiceUUIDsKey] = event.1.map { CBUUID(string: $0) }
                        let device = (FakePeripheral() as RxPeripheralType, advertisment, NSNumber(int: Int32(event.2)))
                        records.append(Recorded(time: event.0, event: .Next(device)))
                    }
                    return records
                }

                beforeEach {
                    let times = ObservableScheduleTimes(createTime: 100, subscribeTime: 300, disposeTime: 1000)
                    let times2 = ObservableScheduleTimes(createTime: 150, subscribeTime: 600, disposeTime: 1400)
                    scanObservers.append(testScheduler.scheduleObservable(times,
                        create: {manager.scanForPeripherals([CBUUID(string: "aaff")])}))
                    scanObservers.append(testScheduler.scheduleObservable(times2,
                        create: {manager.scanForPeripherals([CBUUID(string: "dfff"), CBUUID(string: "aaff")])}))

                    let scans = testScheduler.createHotObservable(createPeripheralEvents(
                        (400, ["aaff", "dfff", "ccaa"], 90),
                        (600, ["aaff", "dfff"], 100),
                        (900, ["aaff", "ccaa"], 120),
                        (1200, ["aaff", "dfff", "efff"], 130)
                        ))

                    fakeCentralManager.rx_didDiscoverPeripheral = scans.asObservable()
                }

                context("when two users are subscribed") {
                    beforeEach {
                        testScheduler.advanceTo(scanObservers[1].subscribeTime)
                    }

                    it("should call scan function once") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }

                    it("should register two scan events for first user") {
                        expect(scanObservers[0].events.count).to(equal(2))
                    }

                    it("should register one scan event for second user") {
                        expect(scanObservers[1].events.count).to(equal(1))
                    }
                }

                context("when both users compleded theirs streams") {
                    beforeEach {
                        testScheduler.start()
                    }

                    it("should call scan function once") {
                        expect(scanCallObserver.events.count).to(equal(1))
                    }

                    it("should call stop function once") {
                        expect(stopScanCallObserver.events.count).to(equal(1))
                    }

                    it("should register three events for first user") {
                        expect(scanObservers[0].events.count).to(equal(3))
                    }

                    it("should register two events for second user, third one should be filtered out") {
                        expect(scanObservers[1].events.count).to(equal(2))
                    }
                }
            }
        }
    }
}