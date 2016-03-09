//
//  UnimplementedError.swift
//  Pods
//
//  Created by Przemysław Lenart on 04/03/16.
//
//

import Foundation
import RxSwift

func unimplementedFunction(file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    fatalError("Unimplemented function \(function) in \(file):\(line)")
}

extension Observable {
    static func unimplemented(file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__)
        -> Observable<Element> {
        unimplementedFunction(file, function: function, line: line)
        return Observable<Element>.empty()
    }
}
