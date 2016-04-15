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

    private func serviceWithIdentifier(identifier: ServiceIdentifier) -> Observable<Service> {
        return Observable.deferred {
            if let services = self.services,
                let service = services.findElement({ $0.UUID == identifier.UUID  }) {
                return Observable.just(service)
            } else {
                return Observable.from(self.discoverServices([identifier.UUID]))
            }
        }
    }

    func characteristicWithIdentifier(identifier: CharacteristicIdentifier) -> Observable<Characteristic> {
        return Observable.deferred {
            return self.serviceWithIdentifier(identifier.service)
                .flatMap { service -> Observable<Characteristic> in
                    if let characteristics = service.characteristics, let characteristic = characteristics.findElement({
                        $0.UUID == identifier.UUID
                    }) {
                        return Observable.just(characteristic)
                    } else {
                        return Observable.from(service.discoverCharacteristics([identifier.UUID]))
                    }
            }
        }
    }

    func descriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return Observable.deferred {
            return self.characteristicWithIdentifier(identifier.characteristic)
                .flatMap { characteristic -> Observable<Descriptor> in
                    if let descriptors = characteristic.descriptors,
                        let descriptor = descriptors.findElement({ $0.UUID == identifier.UUID }) {
                        return Observable.just(descriptor)
                    } else {
                        return Observable.from(characteristic.discoverDescriptors([identifier.UUID]))
                    }
            }
        }
    }

    func monitorWriteForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.monitorWriteForCharacteristic($0)
        }
    }

    func writeValue(data: NSData, forCharacteristicWithIdentifier identifier: CharacteristicIdentifier,
                    type: CBCharacteristicWriteType) -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.writeValue(data, forCharacteristic: $0, type: type)
        }
    }

    func monitorValueUpdateForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.monitorValueUpdateForCharacteristic($0)
        }
    }

    func readValueForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier) -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.readValueForCharacteristic($0)
        }
    }

    func discoverDescriptorsForCharacteristicWithIdentifier(identifier: CharacteristicIdentifier) ->
        Observable<[Descriptor]> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.discoverDescriptorsForCharacteristic($0)
        }
    }

    func monitorWriteForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.monitorWriteForDescriptor($0)
        }
    }

    func writeValue(data: NSData, forDescriptorWithIdentifier identifier: DescriptorIdentifier)
        -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.writeValue(data, forDescriptor: $0)
        }
    }

    func monitorValueUpdateForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.monitorValueUpdateForDescriptor($0)
        }
    }
    func readValueForDescriptorWithIdentifier(identifier: DescriptorIdentifier) -> Observable<Descriptor> {
        return descriptorWithIdentifier(identifier)
            .flatMap {
                return self.readValueForDescriptor($0)
        }
    }
    func setNotifyValue(enabled: Bool, forCharacteristicWithIdentifier identifier: CharacteristicIdentifier)
        -> Observable<Characteristic> {
        return characteristicWithIdentifier(identifier)
            .flatMap {
                return self.setNotifyValue(enabled, forCharacteristic: $0)
        }
    }
}
