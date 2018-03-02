import Foundation
import XCTest
@testable
import RxBluetoothKit

class ThreadSafeBoxTest: XCTestCase {
    var box: ThreadSafeBox<[Int]>!
    
    override func setUp() {
        super.setUp()
        box = ThreadSafeBox(value: [] as [Int])
    }
    
    func testAsync() {
        let expectedIterations = 1000
        var currentIteration = expectedIterations
        
        let expectation = XCTestExpectation(description: "Perform \(expectedIterations) iterations on concurrent threads")
        let resultQueue = DispatchQueue(label: "com.polidea.RxBluetoothKit.ThreadSafeBoxTest")
        
        DispatchQueue.concurrentPerform(iterations: currentIteration) { index in
            let last = box.read { $0.last } ?? 0
            box.write { $0.append(last + 1) }
            
            resultQueue.sync {
                currentIteration -= 1
                // Final loop
                guard currentIteration <= 0 else { return }
                let count = box.read { $0.count }
                
                XCTAssertEqual(count, expectedIterations, "should receive \(expectedIterations), instead received \(count)")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func testWriteAndRead() {
        box.write { $0.append(0) }
        box.write { $0.append(1) }
        var result: [Int]?
        box.read{ result = $0 }
        
        XCTAssertEqual(result?.count, 2, "should have two elements")
        XCTAssertEqual(result!, [0, 1], "should have correct values")
    }
}
