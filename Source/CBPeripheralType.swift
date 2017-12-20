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

import CoreBluetooth

/// CBPeripheralType is protocol that has exact same methods and variables as CBPeripheral
/// and CBPeripheral implements that protocol.
/// It is needed for creating mocks of CBPeripheral in tests.

protocol CBPeripheralType: class {
    var delegate: CBPeripheralDelegate? { get set }
    var state: CBPeripheralState { get }
    var name: String? { get }
    var services: [CBService]? { get }
    var identifier: UUID { get }
    var canSendWriteWithoutResponse: Bool { get }
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    func readValue(for characteristic: CBCharacteristic)
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    func readValue(for descriptor: CBDescriptor)
    func writeValue(_ data: Data, for descriptor: CBDescriptor)
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    func discoverDescriptors(for characteristic: CBCharacteristic)
    func readRSSI()
    #if os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 11, tvOS 11, watchOS 4, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    #endif
}

extension CBPeripheral: CBPeripheralType {
}
