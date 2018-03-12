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
import RxTest
import RxSwift
import CoreBluetooth

class BasePeripheralTest: XCTestCase {
    var peripheral: _Peripheral!
    var centralManagerMock: _CentralManager!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    override func setUp() {
        super.setUp()
        
        centralManagerMock = _CentralManager()
        let peripheralMock = CBPeripheralMock()
        let delegateWrapperMock = CBPeripheralDelegateWrapperMock()
        let notificationManager = CharacteristicNotificationManagerMock(peripheral: peripheralMock, delegateWrapper: delegateWrapperMock)
        peripheral = _Peripheral(manager: centralManagerMock, peripheral: peripheralMock, delegateWrapper: delegateWrapperMock, notificationManager: notificationManager)
        testScheduler = TestScheduler(initialClock: 0, resolution: 1.0, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
        
        centralManagerMock.centralManager.state = .poweredOn
    }
    
    // MARK: - Utils
    
    func createService(uuid: String) -> CBServiceMock {
        let service = CBServiceMock()
        service.uuid = CBUUID(string: uuid)
        return service
    }
    
    func createCharacteristic(uuid: String, service: CBServiceMock? = nil) -> CBCharacteristicMock {
        let characteristic = CBCharacteristicMock()
        characteristic.uuid = CBUUID(string: uuid)
        characteristic.service = service
        
        return characteristic
    }
    
    func createDescriptor(uuid: String, characteristic: CBCharacteristicMock? = nil) -> CBDescriptorMock {
        let descriptor = CBDescriptorMock()
        descriptor.uuid = CBUUID(string: uuid)
        descriptor.characteristic = characteristic
        
        return descriptor
    }
}

