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

import Foundation
import XCTest
import CoreBluetooth
@testable
import RxBluetoothKit

class UUIDIdentifiableTest: XCTestCase {
    func testItemsFilter() {
        let filterList = [
            CBUUID(string: "0x0001"),
            CBUUID(string: "0x0003"),
        ]
        
        let sourceElements = [
            TestElement(uuid: CBUUID(string: "0x0000")),
            TestElement(uuid: CBUUID(string: "0x0001")),
            TestElement(uuid: CBUUID(string: "0x0002")),
            TestElement(uuid: CBUUID(string: "0x0003"))
        ]
        let result = filterUUIDItems(uuids: filterList, items: sourceElements)
        
        XCTAssertNotNil(result, "should return a result")
        XCTAssertEqual(result!, [sourceElements[1], sourceElements[3]], "should filter elements")
    }
    
    func testItemsFilterEmptySourceArray() {
        let filterList = [
            CBUUID(string: "0x0001"),
            CBUUID(string: "0x0003"),
        ]
        
        let result = filterUUIDItems(uuids: filterList, items: [TestElement]())
        
        XCTAssertNil(result, "should return nil")
    }
    
    func testItemsFilterNoCommonElements() {
        let filterList = [
            CBUUID(string: "0x0002"),
            CBUUID(string: "0x0003"),
        ]
        
        let sourceElements = [
            TestElement(uuid: CBUUID(string: "0x0000")),
            TestElement(uuid: CBUUID(string: "0x0001"))
        ]
        let result = filterUUIDItems(uuids: filterList, items: sourceElements)
        
        XCTAssertNil(result, "should return nil")
    }
    
    func testItemsFilterNoAllElementsFound() {
        let filterList = [
            CBUUID(string: "0x0000"),
            CBUUID(string: "0x0001"),
        ]
        
        let sourceElements = [
            TestElement(uuid: CBUUID(string: "0x0000"))
        ]
        let result = filterUUIDItems(uuids: filterList, items: sourceElements)
        
        XCTAssertNil(result, "should return nil")
    }
    
    func testItemsFilterEmptyFilterList() {
        let sourceElements = [
            TestElement(uuid: CBUUID(string: "0x0000")),
            TestElement(uuid: CBUUID(string: "0x0001"))
        ]
        let result = filterUUIDItems(uuids: [CBUUID](), items: sourceElements)
        
        XCTAssertNotNil(result, "should return a result")
        XCTAssertEqual(result!, sourceElements, "should return all elements")
    }
    
    func testItemsFilterNilFilterList() {
        let sourceElements = [
            TestElement(uuid: CBUUID(string: "0x0000")),
            TestElement(uuid: CBUUID(string: "0x0001"))
        ]
        let result = filterUUIDItems(uuids: nil, items: sourceElements)
        
        XCTAssertNotNil(result, "should return a result")
        XCTAssertEqual(result!, sourceElements, "should return all elements")
    }
}

fileprivate struct TestElement: UUIDIdentifiable, Equatable {
    var uuid: CBUUID
}

fileprivate func == (lhs: TestElement, rhs: TestElement) -> Bool {
    return lhs.uuid == rhs.uuid
}
