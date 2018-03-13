import Foundation
import XCTest

class BaseCentralManagerTest: XCTestCase {
    var manager: _CentralManager!
    
    var centralManagerMock: CBCentralManagerMock!
    var wrapperMock: CBCentralManagerDelegateWrapperMock!
    var providerMock: PeripheralProviderMock!
    var connectorMock: ConnectorMock!
    
    func setUpProperties() {
        centralManagerMock = CBCentralManagerMock()
        wrapperMock = CBCentralManagerDelegateWrapperMock()
        providerMock = PeripheralProviderMock()
        connectorMock = ConnectorMock()
        manager = _CentralManager(
            centralManager: centralManagerMock,
            delegateWrapper: wrapperMock,
            peripheralProvider: providerMock,
            connector: connectorMock
        )
    }
}
