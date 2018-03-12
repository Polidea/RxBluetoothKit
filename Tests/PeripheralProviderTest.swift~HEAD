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

class PeripheralProviderTest: XCTestCase {
    
    var provider: _PeripheralProvider!
    var centralManager: _CentralManager!
    
    override func setUp() {
        super.setUp()
        provider = _PeripheralProvider()
        centralManager = _CentralManager()
    }
    
    func testDelegateWrapperReuse() {
        let arg = CBPeripheralMock()
        arg.identifier = UUID()
        
        let result = provider.provide(for: arg, centralManager: centralManager)
        let nextResult = provider.provide(for: arg, centralManager: centralManager)
        
        XCTAssertTrue(result === nextResult, "should reuse previously created Peripheral")
    }
    
    func testDelegateWrapperCreation() {
        let args = (
            firstPeripheral: CBPeripheralMock(),
            secondPeripheral: CBPeripheralMock()
        )
        args.firstPeripheral.identifier = UUID()
        args.secondPeripheral.identifier = UUID()
        
        let result = provider.provide(for: args.firstPeripheral, centralManager: centralManager)
        let nextResult = provider.provide(for: args.secondPeripheral, centralManager: centralManager)
        
        XCTAssertTrue(result !== nextResult, "should create different Peripheral for each peripheral")
    }
}
