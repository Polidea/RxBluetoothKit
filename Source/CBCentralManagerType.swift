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

/// CBCentralManagerType is protocol that has exact same methods and variables as CBCentralManager
/// and CBCentralManager implements that protocol.
/// The only difference here is bluetoothState - it is because in iOS 10 there was type change of
/// state property and we can not create 2 variables with different type and same name.
/// It is needed for creating mocks of CBCentralManager in tests.

protocol CBCentralManagerType: class {
    var delegate: CBCentralManagerDelegate? { get set }
    var bluetoothState: BluetoothState { get }
    func connect(_ peripheral: CBPeripheralType, options: [String: Any]?)
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralType]
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralType]
}

extension CBCentralManager: CBCentralManagerType {
    var bluetoothState: BluetoothState {
        return BluetoothState(rawValue: state.rawValue) ?? .unknown
    }
    func connect(_ peripheral: CBPeripheralType, options: [String: Any]?) {
        if let realPeripheral = peripheral as? CBPeripheral {
            connect(realPeripheral, options: options)
        }
    }
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        if let realPeripheral = peripheral as? CBPeripheral {
            cancelPeripheralConnection(realPeripheral)
        }
    }
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralType] {
        let peripherals: [CBPeripheral] = retrieveConnectedPeripherals(withServices: serviceUUIDs)
        return peripherals as [CBPeripheralType]
    }
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralType] {
        let peripherals: [CBPeripheral] = retrievePeripherals(withIdentifiers: identifiers)
        return peripherals as [CBPeripheralType]
    }
}
