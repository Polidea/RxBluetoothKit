//
//  ScanOperation.swift
//  Pods
//
//  Created by Przemysław Lenart on 26/02/16.
//
//


import Foundation
import CoreBluetooth
import RxSwift

struct ScanOperation {

    let UUIDs: [CBUUID]
    let observable: Observable<ScannedPeripheral>

}