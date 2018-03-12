// The MIT License (MIT)
//
// Copyright (c) 2018 Polidea
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

import XCTest
@testable
import RxBluetoothKit
import RxTest
import RxSwift
import CoreBluetooth

class PeripheralDescriptorsDiscoverTest: BasePeripheralTest {
    var service: _Service!
    var characteristic: _Characteristic!
    
    override func setUp() {
        super.setUp()
        
        let serviceMock = CBServiceMock()
        serviceMock.uuid = CBUUID(string: "0x0000")
        service = _Service(peripheral: peripheral, service: serviceMock)
        peripheral.peripheral.services = [serviceMock]
        
        let characteristicMock = createCharacteristic(uuid: "0x0001", service: serviceMock)
        characteristic = _Characteristic(characteristic: characteristicMock, service: service)
        serviceMock.characteristics = [characteristicMock]
        
        
        peripheral.peripheral.state = .connected
    }
    
    func testDiscoverDescriptors() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic.characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic.characteristic)
        ]
        
        let obs: ScheduledObservable<[_Descriptor]> = testScheduler.scheduleObservable {
            self.peripheral.discoverDescriptors(for: self.characteristic).asObservable()
        }
        testScheduler.scheduleAt(subscribeTime + 100) {
            self.characteristic.characteristic.descriptors = mockDescriptors
            self.peripheral.delegateWrapper.peripheralDidDiscoverDescriptorsForCharacteristic.asObserver().onNext((self.characteristic.characteristic, nil))
        }
        
        testScheduler.advanceTo(subscribeTime + 100)
        
        XCTAssertEqual(peripheral.peripheral.discoverDescriptorsParams.count, 1, "should call discover descriptors for the peripheral")
        XCTAssertEqual(peripheral.peripheral.discoverDescriptorsParams[0], characteristic.characteristic, "should call discover descriptors for correct descriptor")
        XCTAssertDescriptorsList(observable: obs, uuids: mockDescriptors.map { $0.uuid })
    }

    func testDiscoverDescriptorsWithCachedDescriptors() {
        let mockDescriptors = [
            createDescriptor(uuid: "0x0002", characteristic: characteristic.characteristic),
            createDescriptor(uuid: "0x0003", characteristic: characteristic.characteristic)
        ]
        characteristic.characteristic.descriptors = mockDescriptors

        let obs: ScheduledObservable<[_Descriptor]> = testScheduler.scheduleObservable {
            self.peripheral.discoverDescriptors(for: self.characteristic).asObservable()
        }

        testScheduler.advanceTo(subscribeTime)

        XCTAssertEqual(peripheral.peripheral.discoverDescriptorsParams.count, 0, "should not call discover characteristics for the peripheral")
        XCTAssertDescriptorsList(observable: obs, uuids: mockDescriptors.map { $0.uuid })
    }

    // MARK: - Utils

    private func XCTAssertDescriptorsList(observable: ScheduledObservable<[_Descriptor]>, uuids: [CBUUID], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(observable.events.count, 2, "should receive two events", file: file, line: line)
        XCTAssertTrue(observable.events[1].value.isCompleted, "second event should be completed", file: file, line: line)
        let observedDescriptors = observable.events[0].value.element!
        XCTAssertEqual(observedDescriptors.count, uuids.count, "should receive \(uuids.count) descriptors", file: file, line: line)
        for idx in 0..<uuids.count {
            XCTAssertEqual(observedDescriptors[idx].uuid, uuids[idx], "descriptor \(idx) should have correct uuid", file: file, line: line)
        }
    }
}

