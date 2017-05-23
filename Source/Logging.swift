//
//  Logging.swift
//  RxBluetoothKit
//
//  Created by Przemysław Lenart on 23/05/17.
//  Copyright © 2017 Polidea. All rights reserved.
//

import Foundation
import CoreBluetooth

public class RxBluetoothKitLog {

    fileprivate static var currentLogLevel: LogLevel = .none

    public enum LogLevel: Int {
        case none = 0
        case verbose = 1
        case debug = 2
        case info = 3
        case warning = 4
        case error = 5
    }

    public static func setLogLevel(_ logLevel: LogLevel) {
        currentLogLevel = logLevel
    }

    fileprivate static func tag(with logLevel: LogLevel) -> String {
        let prefix: String

        switch logLevel {
        case .none:
            prefix = "[RxBLEKit|NONE|"
        case .verbose:
            prefix = "[RxBLEKit|VERB|"
        case .debug:
            prefix = "[RxBLEKit|DEBG|"
        case .info:
            prefix = "[RxBLEKit|INFO|"
        case .warning:
            prefix = "[RxBLEKit|WARN|"
        case .error:
            prefix = "[RxBLEKit|ERRO|"
        }
        let time = Date().timeIntervalSinceReferenceDate
        return prefix + String(format: "%02.0f:%02.0f:%02.0f.%03.f]:",
                               floor(time / 3600.0).truncatingRemainder(dividingBy: 24),
                               floor(time / 60.0).truncatingRemainder(dividingBy: 60),
                               floor(time).truncatingRemainder(dividingBy: 60),
                               floor(time * 1000).truncatingRemainder(dividingBy: 1000))
    }

    fileprivate static func log(with logLevel: LogLevel, message: @autoclosure () -> String) {
        if currentLogLevel >= logLevel {
            print(tag(with: logLevel), message())
        }
    }

    static func v(_ message:  @autoclosure () -> String) {
        log(with: .verbose, message: message)
    }

    static func d(_ message:  @autoclosure () -> String) {
        log(with: .debug, message: message)
    }

    static func i(_ message:  @autoclosure () -> String) {
        log(with: .info, message: message)
    }

    static func w(_ message:  @autoclosure () -> String) {
        log(with: .warning, message: message)
    }

    static func e(_ message:  @autoclosure () -> String) {
        log(with: .error, message: message)
    }
}

extension RxBluetoothKitLog.LogLevel : Comparable {
    public static func < (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    public static func == (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

protocol Loggable {
    var logDescription: String { get }
}

extension Data : Loggable {
    var logDescription: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

extension CBCentralManager : Loggable {
    var logDescription: String {
        return "CentralManager(\(UInt(bitPattern: ObjectIdentifier(self)))"
    }
}

extension CBPeripheral : Loggable {
    var logDescription: String {
        return "Peripheral(uuid: \(identifier), name: \(name))"
    }
}

extension CBCharacteristic : Loggable {
    var logDescription: String {
        return "Characteristic(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self))))"
    }
}

extension CBService : Loggable {
    var logDescription: String {
        return "Service(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self))))"
    }
}

extension CBDescriptor : Loggable {
    var logDescription: String {
        return "Service(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self))))"
    }
}

extension Array where Element: Loggable {
    var logDescription: String {
        return "[\(self.map { $0.logDescription }.joined(separator: ", "))]"
    }
}
