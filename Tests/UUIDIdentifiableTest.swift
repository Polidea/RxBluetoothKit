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
