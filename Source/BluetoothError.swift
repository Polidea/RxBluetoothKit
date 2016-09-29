// The MIT License (MIT)
//
// Copyright (c) 2016 Polidea
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

/// Bluetooth error which can be emitted by RxBluetoothKit created observables.
public enum BluetoothError: Error {
    // States
    case bluetoothUnsupported
    case bluetoothUnauthorized
    case bluetoothPoweredOff
    case bluetoothInUnknownState
    case bluetoothResetting
    // Peripheral
    case peripheralConnectionFailed(Peripheral, Error?)
    case peripheralDisconnected(Peripheral, Error?)
    case peripheralRSSIReadFailed(Peripheral, Error?)
    // Services
    case servicesDiscoveryFailed(Peripheral, Error?)
    case includedServicesDiscoveryFailed(Peripheral, Error?)
    // Characteristics
    case characteristicsDiscoveryFailed(Service, Error?)
    case characteristicWriteFailed(Characteristic, Error?)
    case characteristicReadFailed(Characteristic, Error?)
    case characteristicNotifyChangeFailed(Characteristic, Error?)
    // Descriptors
    case descriptorsDiscoveryFailed(Characteristic, Error?)
    case descriptorWriteFailed(Descriptor, Error?)
    case descriptorReadFailed(Descriptor, Error?)
}

extension BluetoothError : CustomStringConvertible {

    /// Human readable description of bluetooth error
    public var description: String {
        switch self {
        case .bluetoothUnsupported:
            return "Bluetooth is unsupported"
        case .bluetoothUnauthorized:
            return "Bluetooth is unauthorized"
        case .bluetoothPoweredOff:
            return "Bluetooth is powered off"
        case .bluetoothInUnknownState:
            return "Bluetooth is in unknown state"
        case .bluetoothResetting:
            return "Bluetooth is resetting"
        // Peripheral
        case .peripheralConnectionFailed(_, let err):
            return "Connection error has occured: \(err?.localizedDescription ?? "-")"
        case .peripheralDisconnected(_, let err):
            return "Connection error has occured: \(err?.localizedDescription ?? "-")"
        case .peripheralRSSIReadFailed(_, let err):
            return "RSSI read failed : \(err?.localizedDescription ?? "-")"
        // Services
        case .servicesDiscoveryFailed(_, let err):
            return "Services discovery error has occured: \(err?.localizedDescription ?? "-")"
        case .includedServicesDiscoveryFailed(_, let err):
            return "Included services discovery error has occured: \(err?.localizedDescription ?? "-")"
        // Characteristics
        case .characteristicsDiscoveryFailed(_, let err):
            return "Characteristics discovery error has occured: \(err?.localizedDescription ?? "-")"
        case .characteristicWriteFailed(_, let err):
            return "Characteristic write error has occured: \(err?.localizedDescription ?? "-")"
        case .characteristicReadFailed(_, let err):
            return "Characteristic read error has occured: \(err?.localizedDescription ?? "-")"
        case .characteristicNotifyChangeFailed(_, let err):
            return "Characteristic notify change error has occured: \(err?.localizedDescription ?? "-")"
        //Descriptors
        case .descriptorsDiscoveryFailed(_, let err):
            return "Descriptor discovery error has occured: \(err?.localizedDescription ?? "-")"
        case .descriptorWriteFailed(_, let err):
            return "Descriptor write error has occured: \(err?.localizedDescription ?? "-")"
        case .descriptorReadFailed(_, let err):
            return "Descriptor read error has occured: \(err?.localizedDescription ?? "-")"
        }
    }
}
extension BluetoothError {
    init?(state: BluetoothState) {
        switch state {
        case .unsupported:
            self = .bluetoothUnsupported
        case .unauthorized:
            self = .bluetoothUnauthorized
        case .poweredOff:
            self = .bluetoothPoweredOff
        case .unknown:
            self = .bluetoothInUnknownState
        case .resetting:
            self = .bluetoothResetting
        default:
            return nil
        }
    }

}

extension BluetoothError: Equatable {}

//swiftlint:disable cyclomatic_complexity
/**
 Compares two Bluetooth erros if they are the same.

 - parameter lhs: First bluetooth error
 - parameter rhs: Second bluetooth error
 - returns: True if both bluetooth errors are the same
 */
public func == (lhs: BluetoothError, rhs: BluetoothError) -> Bool {
    switch (lhs, rhs) {
    case (.bluetoothUnsupported, .bluetoothUnsupported): return true
    case (.bluetoothUnauthorized, .bluetoothUnauthorized): return true
    case (.bluetoothPoweredOff, .bluetoothPoweredOff): return true
    case (.bluetoothInUnknownState, .bluetoothInUnknownState): return true
    case (.bluetoothResetting, .bluetoothResetting): return true
    // Services
    case (.servicesDiscoveryFailed(let l, _), .servicesDiscoveryFailed(let r, _)): return l == r
    case (.includedServicesDiscoveryFailed(let l, _), .includedServicesDiscoveryFailed(let r, _)): return l == r
    // Peripherals
    case (.peripheralConnectionFailed(let l, _), .peripheralConnectionFailed(let r, _)): return l == r
    case (.peripheralDisconnected(let l, _), .peripheralDisconnected(let r, _)): return l == r
    case (.peripheralRSSIReadFailed(let l, _), .peripheralRSSIReadFailed(let r, _)): return l == r
    // Characteristics
    case (.characteristicsDiscoveryFailed(let l, _), .characteristicsDiscoveryFailed(let r, _)): return l == r
    case (.characteristicWriteFailed(let l, _), .characteristicWriteFailed(let r, _)): return l == r
    case (.characteristicReadFailed(let l, _), .characteristicReadFailed(let r, _)): return l == r
    case (.characteristicNotifyChangeFailed(let l, _), .characteristicNotifyChangeFailed(let r, _)): return l == r
    // Descriptors
    case (.descriptorsDiscoveryFailed(let l, _), .descriptorsDiscoveryFailed(let r, _)): return l == r
    case (.descriptorWriteFailed(let l, _), .descriptorWriteFailed(let r, _)): return l == r
    case (.descriptorReadFailed(let l, _), .descriptorReadFailed(let r, _)): return l == r
    default: return false
    }
}
//swiftlint:enable cyclomatic_complexity
