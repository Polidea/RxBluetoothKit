//
//  BluetoothError.swift
//  Pods
//
//  Created by Przemysław Lenart on 04/03/16.
//
//

import Foundation
import CoreBluetooth

/// Bluetooth error which can be emitted by RxBluetoothKit created observables.
public enum BluetoothError: ErrorType {
    // States
    case BluetoothUnsupported
    case BluetoothUnauthorized
    case BluetoothPoweredOff
    case BluetoothInUnknownState
    case BluetoothResetting
    // Peripheral
    case PeripheralConnectionFailed(Peripheral, NSError?)
    case PeripheralDisconnected(Peripheral, NSError?)
    case PeripheralRSSIReadFailed(Peripheral, NSError?)
    // Services
    case ServicesDiscoveryFailed(Peripheral, NSError?)
    case IncludedServicesDiscoveryFailed(Peripheral, NSError?)
    // Characteristics
    case CharacteristicsDiscoveryFailed(Service, NSError?)
    case CharacteristicWriteFailed(Characteristic, NSError?)
    case CharacteristicReadFailed(Characteristic, NSError?)
    case CharacteristicNotifyChangeFailed(Characteristic, NSError?)
    // Descriptors
    case DescriptorsDiscoveryFailed(Characteristic, NSError?)
}

extension BluetoothError : CustomStringConvertible {

    /// Human readable description of bluetooth error
    public var description: String {
        switch self {
        case .BluetoothUnsupported:
            return "Bluetooth is unsupported"
        case .BluetoothUnauthorized:
            return "Bluetooth is unauthorized"
        case .BluetoothPoweredOff:
            return "Bluetooth is powered off"
        case .BluetoothInUnknownState:
            return "Bluetooth is in unknown state"
        case .BluetoothResetting:
            return "Bluetooth is resetting"
        // Peripheral
        case .PeripheralConnectionFailed(_, let err):
            return "Connection error has occured: \(err?.description ?? "-")"
        case .PeripheralDisconnected(_, let err):
            return "Connection error has occured: \(err?.description ?? "-")"
        case .PeripheralRSSIReadFailed(_, let err):
            return "RSSI read failed : \(err?.description ?? "-")"
        // Services
        case .ServicesDiscoveryFailed(_, let err):
            return "Services discovery error has occured: \(err?.description ?? "-")"
        case .IncludedServicesDiscoveryFailed(_, let err):
            return "Included services discovery error has occured: \(err?.description ?? "-")"
        // Characteristics
        case .CharacteristicsDiscoveryFailed(_, let err):
            return "Characteristics discovery error has occured: \(err?.description ?? "-")"
        case .CharacteristicWriteFailed(_, let err):
            return "Characteristic write error has occured: \(err?.description ?? "-")"
        case .CharacteristicReadFailed(_, let err):
            return "Characteristic read error has occured: \(err?.description ?? "-")"
        case .CharacteristicNotifyChangeFailed(_, let err):
            return "Characteristic notify change error has occured: \(err?.description ?? "-")"
        //Descriptors
        case .DescriptorsDiscoveryFailed(_, let err):
            return "Descriptor discovery error has occured: \(err?.description ?? "-")"
        }
    }
}
extension BluetoothError {
    static func errorFromState(state: CBCentralManagerState) -> BluetoothError? {
        switch state {
        case .Unsupported:
            return .BluetoothUnsupported
        case .Unauthorized:
            return .BluetoothUnauthorized
        case .PoweredOff:
            return .BluetoothPoweredOff
        case .Unknown:
            return .BluetoothInUnknownState
        case .Resetting:
            return .BluetoothResetting
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
    case (.BluetoothUnsupported, .BluetoothUnsupported): return true
    case (.BluetoothUnauthorized, .BluetoothUnauthorized): return true
    case (.BluetoothPoweredOff, .BluetoothPoweredOff): return true
    case (.BluetoothInUnknownState, .BluetoothInUnknownState): return true
    case (.BluetoothResetting, .BluetoothResetting): return true
    // Services
    case (.ServicesDiscoveryFailed(let l, _), .ServicesDiscoveryFailed(let r, _)): return l == r
    case (.IncludedServicesDiscoveryFailed(let l, _), .IncludedServicesDiscoveryFailed(let r, _)): return l == r
    // Peripherals
    case (.PeripheralConnectionFailed(let l, _), .PeripheralConnectionFailed(let r, _)): return l == r
    case (.PeripheralDisconnected(let l, _), .PeripheralDisconnected(let r, _)): return l == r
    case (.PeripheralRSSIReadFailed(let l, _), .PeripheralRSSIReadFailed(let r, _)): return l == r
    // Characteristics
    case (.CharacteristicsDiscoveryFailed(let l, _), .CharacteristicsDiscoveryFailed(let r, _)): return l == r
    case (.CharacteristicWriteFailed(let l, _), .CharacteristicWriteFailed(let r, _)): return l == r
    case (.CharacteristicReadFailed(let l, _), .CharacteristicReadFailed(let r, _)): return l == r
    case (.CharacteristicNotifyChangeFailed(let l, _), .CharacteristicNotifyChangeFailed(let r, _)): return l == r
    // Descriptors
    case (.DescriptorsDiscoveryFailed(let l, _), .DescriptorsDiscoveryFailed(let r, _)): return l == r

    default: return false
    }
}
//swiftlint:enable cyclomatic_complexity
