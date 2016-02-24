//
//  CollectionUtils.swift
//  Pods
//
//  Created by Przemysław Lenart on 26/02/16.
//
//

import Foundation

extension SequenceType {
    func findElement(@noescape match: Generator.Element -> Bool) -> Generator.Element? {
        for elem in self where match(elem) {
            return elem
        }
        return nil
    }
}