import Foundation
import XCTest
@testable
import RxBluetoothKit

class ArrayUtilsTest: XCTestCase {
    func testRemoveElement() {
        var array: [Int] = [0, 1, 2, 3]
        let res = array.remove(object: 1)
        
        XCTAssertTrue(res, "should return true")
        XCTAssertEqual(array, [0, 2, 3], "should remove one element")
    }
    
    func testRemoveNoElementFound() {
        var array: [Int] = [0, 1, 2, 3]
        let res = array.remove(object: 4)
        
        XCTAssertFalse(res, "should return false")
        XCTAssertEqual(array, [0, 1, 2, 3], "should not remove any element")
    }
}
