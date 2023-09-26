import Foundation
import RxSwift

func unimplementedFunction(file: String = #file, function: String = #function, line: Int = #line) {
    fatalError("Unimplemented function \(function) in \(file):\(line)")
}

extension RxSwift.Observable {
    static func unimplemented(file: String = #file, function: String = #function, line: Int = #line)
    -> RxSwift.Observable<Element> {
        unimplementedFunction(file: file, function: function, line: line)
        return RxSwift.Observable<Element>.empty()
    }
}
