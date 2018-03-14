import XCTest

class PeripheralProviderTest: XCTestCase {
    
    var provider: _PeripheralProvider!
    var centralManager: _CentralManager!
    
    override func setUp() {
        super.setUp()
        provider = _PeripheralProvider()
        centralManager = _CentralManager()
    }
    
    func testPeripheralWrapperReuse() {
        let arg = CBPeripheralMock()
        arg.uuidIdentifier = UUID()
        
        let result = provider.provide(for: arg, centralManager: centralManager)
        let nextResult = provider.provide(for: arg, centralManager: centralManager)
        
        XCTAssertTrue(result === nextResult, "should reuse previously created Peripheral")
    }
    
    func testPeripheralWrapperCreation() {
        let args = (
            firstPeripheral: CBPeripheralMock(),
            secondPeripheral: CBPeripheralMock()
        )
        args.firstPeripheral.uuidIdentifier = UUID()
        args.secondPeripheral.uuidIdentifier = UUID()
        
        let result = provider.provide(for: args.firstPeripheral, centralManager: centralManager)
        let nextResult = provider.provide(for: args.secondPeripheral, centralManager: centralManager)
        
        XCTAssertTrue(result !== nextResult, "should create different Peripheral for each peripheral")
    }
    
    func testPeripheralDelegateWrapperCreation() {
        let args = (
            firstPeripheral: CBPeripheralMock(),
            secondPeripheral: CBPeripheralMock()
        )
        args.firstPeripheral.uuidIdentifier = UUID()
        args.secondPeripheral.uuidIdentifier = UUID()
        
        let result = provider.provideDelegateWrapper(for: args.firstPeripheral)
        let nextResult = provider.provideDelegateWrapper(for: args.secondPeripheral)
        
        XCTAssertTrue(result !== nextResult, "should create different Peripheral Delegate for each peripheral")
    }
    
    func testPeripheralDelegateWrapperReuse() {
        let arg = CBPeripheralMock()
        arg.uuidIdentifier = UUID()
        
        let result = provider.provideDelegateWrapper(for: arg)
        let nextResult = provider.provideDelegateWrapper(for: arg)
        
        XCTAssertTrue(result === nextResult, "should reuse previously created Peripheral Delegate")
    }
}
