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
import CoreBluetooth
@testable import RxBluetoothKit

#if os(iOS)
    /// Convenience class which helps reading state of restored _BluetoothManager.
    struct _RestoredState {

        /// Restored state dictionary.
        let restoredStateData: [String: Any]

        unowned let bluetoothManager: _BluetoothManager
        /// Creates restored state information based on CoreBluetooth's dictionary
        /// - parameter restoredStateDictionary: Core Bluetooth's restored state data
        /// - parameter bluetoothManager: `_BluetoothManager` instance of which state has been restored.
        init(restoredStateDictionary: [String: Any], bluetoothManager: _BluetoothManager) {
            restoredStateData = restoredStateDictionary
            self.bluetoothManager = bluetoothManager
        }

        /// Array of `_Peripheral` objects which have been restored.
        /// These are peripherals that were connected to the central manager (or had a connection pending)
        /// at the time the app was terminated by the system.
        var peripherals: [_Peripheral] {
            let objects = restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [AnyObject]
            guard let arrayOfAnyObjects = objects else { return [] }
            return arrayOfAnyObjects.flatMap { $0 as? CBPeripheralMock }
                .map { _Peripheral(manager: bluetoothManager, peripheral: $0) }
        }

        /// Dictionary that contains all of the peripheral scan options that were being used
        /// by the central manager at the time the app was terminated by the system.
        var scanOptions: [String: AnyObject]? {
            return restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [String: AnyObject]
        }

        /// Array of `_Service` objects which have been restored.
        /// These are all the services the central manager was scanning for at the time the app
        /// was terminated by the system.
        var services: [_Service] {
            let objects = restoredStateData[CBCentralManagerRestoredStateScanServicesKey] as? [AnyObject]
            guard let arrayOfAnyObjects = objects else { return [] }
            return arrayOfAnyObjects.flatMap { $0 as? CBServiceMock }
                .map { _Service(peripheral: _Peripheral(manager: bluetoothManager, peripheral: $0.peripheral),
                               service: $0) }
        }
    }
#endif
