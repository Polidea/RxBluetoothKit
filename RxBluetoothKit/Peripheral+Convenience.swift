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
import RxSwift

extension Peripheral {

    private func getService(id: ServiceIdentifier) -> Observable<Service> {
        return Observable.deferred {
            if let services = self.services,
                let service = services.findElement({ $0.UUID == id.UUID  }) {
                return Observable.just(service)
            } else {
                return Observable.from(self.discoverServices([id.UUID]))
            }
        }
    }

    func getCharacteristic(id: CharacteristicIdentifier) -> Observable<Characteristic> {
        return Observable.deferred {
            return self.getService(id.service)
                .flatMap { service -> Observable<Characteristic> in
                    if let characteristics = service.characteristics, let characteristic = characteristics.findElement({
                        $0.UUID == id.UUID
                    }) {
                        return Observable.just(characteristic)
                    } else {
                        return Observable.from(service.discoverCharacteristics([id.UUID]))
                    }
            }
        }
    }

    func getDescriptor(id: DescriptorIdentifier) -> Observable<Descriptor> {
        return Observable.deferred {
            return self.getCharacteristic(id.characteristic)
                .flatMap { characteristic -> Observable<Descriptor> in
                    if let descriptors = characteristic.descriptors,
                        let descriptor = descriptors.findElement({ $0.UUID == id.UUID }) {
                        return Observable.just(descriptor)
                    } else {
                        return Observable.from(characteristic.discoverDescriptors([id.UUID]))
                    }
            }
        }
    }

    func monitorWriteForCharacteristicWithId(id: CharacteristicIdentifier) -> Observable<Characteristic> {
        return getCharacteristic(id)
            .flatMap {
                return self.monitorWriteForCharacteristic($0)
        }
    }

    func writeValue(data: NSData, forCharacteristicWithId id: CharacteristicIdentifier, type: CBCharacteristicWriteType)
        -> Observable<Characteristic> {
        return getCharacteristic(id)
            .flatMap {
                return self.writeValue(data, forCharacteristic: $0, type: type)
        }
    }

    func monitorValueUpdateForCharacteristicWithId(id: CharacteristicIdentifier) -> Observable<Characteristic> {
        return getCharacteristic(id)
            .flatMap {
                return self.monitorValueUpdateForCharacteristic($0)
        }
    }

    func readValueForCharacteristicWithId(id: CharacteristicIdentifier) -> Observable<Characteristic> {
        return getCharacteristic(id)
            .flatMap {
                return self.readValueForCharacteristic($0)
        }
    }

    func discoverDescriptorsForCharacteristicWithId(id: CharacteristicIdentifier) -> Observable<[Descriptor]> {
        return getCharacteristic(id)
            .flatMap {
                return self.discoverDescriptorsForCharacteristic($0)
        }
    }

    func monitorWriteForDescriptorWithId(id: DescriptorIdentifier) -> Observable<Descriptor> {
        return getDescriptor(id)
            .flatMap {
                return self.monitorWriteForDescriptor($0)
        }
    }

    func writeValue(data: NSData, forDescriptorWithId id: DescriptorIdentifier) -> Observable<Descriptor> {
        return getDescriptor(id)
            .flatMap {
                return self.writeValue(data, forDescriptor: $0)
        }
    }

    func monitorValueUpdateForDescriptorWithId(id: DescriptorIdentifier) -> Observable<Descriptor> {
        return getDescriptor(id)
            .flatMap {
                return self.monitorValueUpdateForDescriptor($0)
        }
    }
    func readValueForDescriptorWithId(id: DescriptorIdentifier) -> Observable<Descriptor> {
        return getDescriptor(id)
            .flatMap {
                return self.readValueForDescriptor($0)
        }
    }
    func setNotifyValue(enabled: Bool,
                        forCharacteristicWithId id: CharacteristicIdentifier) -> Observable<Characteristic> {
        return getCharacteristic(id)
            .flatMap {
                return self.setNotifyValue(enabled, forCharacteristic: $0)
        }
    }
}
