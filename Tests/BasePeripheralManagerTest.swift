import Foundation
import XCTest

class BasePeripheralManagerTest: XCTestCase {
    var manager: _PeripheralManager!

    var peripheralManagerMock: CBPeripheralManagerMock!
    var wrapperMock: CBPeripheralManagerDelegateWrapperMock!

    func setUpProperties() {
        peripheralManagerMock = CBPeripheralManagerMock()
        wrapperMock = CBPeripheralManagerDelegateWrapperMock()
        peripheralManagerMock.isAdvertising = false
        manager = _PeripheralManager(
            peripheralManager: peripheralManagerMock,
            delegateWrapper: wrapperMock
        )
    }
}
