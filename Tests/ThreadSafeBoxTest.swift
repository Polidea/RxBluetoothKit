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
}
