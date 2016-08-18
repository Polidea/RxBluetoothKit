//
//  BluetoothPeripheralManager.swift
//  RxBluetoothKit
//
//  Created by Andrew Breckenridge on 6/14/16.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

public class BluetoothPeripheralManager {
    
    /// Implementation of Peripheral Manager
    private let peripheralManager: RxPeripheralManagerType
    
    /// Queue on which all observables are serialised if needed
    private let subscriptionQueue: SerializedSubscriptionQueue
    
    /// Lock which should be used before accessing any internal structures
    private let lock = NSLock()
    
    let disposeBag = DisposeBag()
    
    init(peripheralManager: RxPeripheralManagerType,
         queueScheduler: SchedulerType = ConcurrentMainScheduler.instance) {
        self.peripheralManager = peripheralManager
        self.subscriptionQueue = SerializedSubscriptionQueue(scheduler: queueScheduler)
    }
    
    convenience public init(queue: dispatch_queue_t = dispatch_get_main_queue(),
                            options: [String : AnyObject]? = nil) {
        self.init(peripheralManager: RxCBPeripheralManager(queue: queue),
                  queueScheduler: ConcurrentDispatchQueueScheduler(queue: queue))
    }
    
}