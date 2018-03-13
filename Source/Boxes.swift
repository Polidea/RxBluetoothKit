// The MIT License (MIT)
//
// Copyright (c) 2017 Polidea
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

class WeakBox<T: AnyObject>: CustomDebugStringConvertible {
    weak var value: T?
    init() {}
    init(value: T) {
        self.value = value
    }
}

extension WeakBox {
    var debugDescription: String {
        return "WeakBox(\(String(describing: value)))"
    }
}

/// `ThreadSafeBox` is a helper class that allows use of resource (value) in a thread safe manner.
/// All read and write calls are wrapped in concurrent `DispatchQueue` which protects writing to
/// resource from more than 1 thread at a time.
class ThreadSafeBox<T>: CustomDebugStringConvertible {
    private let queue = DispatchQueue(label: "com.polidea.RxBluetoothKit.ThreadSafeBox")
    private var value: T
    init(value: T) {
        self.value = value
    }

    func read<Result: Any>(_ block: (T) -> Result) -> Result {
        var result: Result! = nil
        queue.sync {
            result = block(value)
        }
        return result
    }

    func write(_ block: @escaping (inout T) -> Void) {
        queue.async {
            block(&self.value)
        }
    }

    @discardableResult func compareAndSet(compare: (T) -> Bool, set: @escaping (inout T) -> Void) -> Bool {
        var result: Bool = false
        queue.sync {
            result = compare(value)
            if result {
                set(&self.value)
            }
        }
        return result
    }
}

extension ThreadSafeBox {
    var debugDescription: String {
        return "ThreadSafeBox(\(String(describing: value)))"
    }
}
