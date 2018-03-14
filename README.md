![RxBluetoothKit Swift](http://i.imgur.com/aeT4p5o.png)

[![CI Status](http://img.shields.io/travis/Polidea/RxBluetoothKit.svg?style=flat)](https://travis-ci.org/Polidea/RxBluetoothKit)
[![Platform](https://img.shields.io/cocoapods/p/RxBluetoothKit.svg?style=flat)](http://cocoapods.org/pods/RxBluetoothKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

RxBluetoothKit is an Bluetooth library that makes interaction with BLE devices much more pleasant. It's backed by RxSwift and CoreBluetooth.
Provides nice API to work with, and makes your code more readable, reliable and easier to maintain.

* 3.0 version supports Swift 3.0 and 3.1
* 5.0 version of the library supports Swift 3.2 and 4.0


## Documentation & Support

Documentation can be found [here](https://polidea.github.io/RxBluetoothKit/).

Want to talk about it? Ask questions? Give feedback? Join our discussion on [Gitter](https://gitter.im/RxBLELibraries/RxBluetoothKit?utm_source=share-link&utm_medium=link&utm_campaign=share-link)!

For support head to [StackOverflow](http://stackoverflow.com/questions/tagged/rxiosble?sort=active) or open [an issue](https://github.com/Polidea/RxBluetoothKit/issues/new) on GitHub.

Follow [Polidea's Blog](https://www.polidea.com/blog/RxBluetoothKit_The_most_simple_way_to_code_BLE_devices/) blog to get all the news and updates!

## Features
- [x] CBCentralManger RxSwift support
- [x] CBPeripheral RxSwift support
- [x] Scan sharing
- [x] Scan queueing
- [x] Bluetooth error bubbling

## Sample
In Example folder you can find application we've provided to you. It's a great place to dig in, once you want to see everything in action. App provides most of the common usages of RxBluetoothKit.

## Installation

### CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for CocoaProjects.
To integrate RxBluetoothKit into your Xcode project using CocoaPods specify it in your `Podfile`:
```ruby
pod 'RxBluetoothKit'
```
Then, run following command:
`$ pod install`

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.
To integrate RxBluetoothKit into your Xcode project using Carthage  specify it in your `Cartfile`:
```swift
github "Polidea/RxBluetoothKit"
```
Then, run `carthage update` to build framework and drag `RxBluetoothKit.framework` into your Xcode project.

### Swift Package Manager

Versions >= 4.0 of the library integrate with the Swift Package Manager. In order to do that please specify our project as one of your dependencies in `Package.swift` file.

## Architecture
Library is built on top of Apple's CoreBluetooth.
It has multiple components, that should be familiar to you:

- CentralManager
- ScannedPeripheral
- Peripheral
- Service
- Characteristic
- Descriptor

Every one of them is backed by it's CB counterpart hidden behind layer of abstraction. We've chosen this architecture, because we believe in *testing*.

## Usage

To begin work you should create an instance of CentralManager. Doing it is really easy - all you need to specify is queue(main queue is used by default):
```swift
let manager = CentralManager(queue: .main)
```
You are responsible for maintaining instance of manager object, and passing it between parts of your app.
**Note:** All operations are executed in queue which you have provided, so make sure to observe UI related effects in main thread when it's needed.

### Scanning peripherals
To start any interaction, with bluetooth devices, you have to first scan some of them. So - get ready!
#### Basic

```swift
manager.scanForPeripherals(withServices: serviceIds)
    .subscribe(onNext: { scannedPeripheral in
        let advertisementData = scannedPeripheral.advertisementData
    })
```
This is the simplest version of this operation. After subscription to observable, scan is performed infinitely.  What you receive from method is `ScannedPeripheral` instance, that provides access to following information:
- Peripheral: object that you can use, to perform actions like connecting, discovering services etc.
- AdvertisementData: strongly typed wrapper around CBPeripheral advertisement data dictionary.. Thanks to it, you no longer have to worry about all of the keys needed to pull out information.
- RSSI

#### Cancelling
By default scanning operation is not cancelled. It's the user's responsibility to do that in situations where scanning in not needed anymore.
Fortunately, this is also really easy to do, thanks to awesome RxSwift operators.

```swift
manager.scanForPeripherals(withServices: [serviceIds]).take(1)
//Doing this, after first received result, scan is immediately cancelled.
```
Ok, that's fun, but what if you also want to apply timeout policy? That's also easy to do:

```swift
manager.scanForPeripherals(withServices: [serviceIds]).timeout(3.0, timerScheduler)
```

As you can see: thanks to all available RxSwift operators, in a simple way you might create really interesting and complex usage scenarios, like for example retrying scans, if you receive timeout.

#### Waiting for proper BluetoothState
In a following scenario: just after app launch, you want to perform scans. But, there are some problems with this approach - in order to perform work with bluetooth, you're manager should be in **.poweredOn** state. Specially for this case, our library provides you with another observable, that you should use for monitoring state.
```swift
let stateObservable = manager.observeState()
```
This observable will emit next event with new value of BluetoothManager state every time state changes.
You could easily chain it with operation you want to perform after changing to proper state. To get current bluetooth state, use `CentralManager.state`
property. Let's see how it looks with scanning:
```swift
manager.observeState()
	.startWith(manager.state)
	.filter { $0 == .poweredOn }
	.timeout(3.0, scheduler)
	.take(1)
	.flatMap { _ in manager.scanForPeripherals(withServices: [serviceId]) }
```
Firstly, use `CentralManager.state` as a start value, next filter .poweredOn from states stream. Like above, we want to apply timeout policy to state changes. Also, we use **take** to be sure, that after getting .poweredOn state, nothing else ever will be emitted by the observable.
In last `flatMap` operation bluetooth is ready to perform further operations.

### Connecting
After receiving scanned peripheral, to do something with it, we need to first call `establishConnection`.
It's really straightforward: just flatMap result into another Observable!
```swift
manager.scanForPeripherals(withServices: [serviceId]).take(1)
	.flatMap { $0.peripheral.establishConnection() }
	.subscribe(onNext: { peripheral in
		print("Connected to: \(peripheral)")
	})
```


### Discovering services
After connecting, the most common task is to discover Services.
Because all of wanted services are discovered at once, method returns `Single<[Service]>`.  In order to make it into `Observable<Service>` and fire for each of service discovered, we advice you to use our RxSwift operator `Observable.from()`

Here's how it works in RxBluetoothKit:
```swift
peripheral.establishConnection()
	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
	.flatMap { Observable.from($0) }
	.subscribe(onNext: { service in
		print("Discovered service: \(service)")
	})
```

### Discovering characteristics
Discovering characteristics method is very similar to **discoverServices**.
This time API's returning `Observable<[Characteristic]>` and to process one
characteristic at a time, you need to once again use `Observable.from()`
```swift
peripheral.establishConnection()
	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
	.flatMap { Observable.from($0) }
	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
	.flatMap { Observable.from($0) }
	.subscribe(onNext: { characteristic in
		print("Discovered characteristic: \(characteristic)")
	})
```

### Reading value of characteristic
Once you've got characteristic, next common step is to read value from it.
In order to do that, you should use `readValue()` function defined on `Characteristic`. It returns `Observable<Characteristic>` which emits element, when value of characteristic is ready to read.
We decided to return `Characteristic` instead of `NSData` due to one purpose - to allow you chain operations on characteristic in easy way.
```swift
peripheral.establishConnection()
	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
	.flatMap { Observable.from($0) }
	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
	.flatMap { Observable.from($0) }
	.flatMap { $0.readValue() }
	.subscribe(onNext: {
		let data = $0.value
	})
```

### Notifying on characteristic changes
Notifying on characteristic value changes? Nothing easier.
After subscribing observable returned by this method, you will get proper message every single time:
```swift
let disposable = characteristic.observeValueUpdateAndSetNotification()
	.subscribe(onNext: {
		let newValue = $0.value
	})
```
If you are not interested anymore in updates, just unsubscribe:
```swift
disposable.dispose()
```

### Writing value to characteristic
While deciding to write to characteristic you have two writing options, that determine write behavior:
- withResponse
- withoutResponse

Choosing `withResponse`, you're waiting to receive .next event on Observable while device has confirmed that value has been written to it. Also, if any error has ocurred - you will receive `.error` on Observable.
On the other hand - if you decided to go with `withoutResponse` - you're receiving Characteristic just after write command has been called. Also, no errors will be emitted.
Let's jump over to the code:
```swift
characteristic.writeValue(data, type: .withResponse)
	.subscribe { event in
		//respond to errors / successful read
	}
```

### Convenience calling methods
In order to enable even easier interaction with RxBluetooth, we've provided custom protocols we advice you to implement.
Thats `ServiceIdentifier`, `CharacteristicIdentifier` and `DescriptorIdentifier`. Most of the time you're writing Bluetooth code to communicate with specific device, while knowing its specification like services and characteristic. Thats exactly the case, where you should implement these protocols. Sample implementation might look like:
```swift
enum DeviceCharacteristic: String, CharacteristicIdentifier {
    case manufacturerName = "2A29"

    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
		//Service to which characteristic belongs
    var service: ServiceIdentifier {
        switch self {
        case .ManufacturerName:
            return XXXService.DeviceInformation
        }
    }
}
enum DeviceService: String, ServiceIdentifier {
    case deviceInformation = "180A"

    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
}
```
After implementing these types, whole set of new new methods is becoming available.
Earlier implementation of reading from characteristic looked like that:
```swift
peripheral.establishConnection()
	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
	.flatMap { Observable.from($0) }
	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
	.flatMap { Observable.from($0) }
	.flatMap { $0.readValue() }
	.subscribe(onNext: {
		let data = $0.value
	})
```

When you use new `CharacteristicIdentifier` protocol, you could do it way simpler:

```swift
peripheral.establishConnection()
    .flatMap { $0.readValue(for: DeviceCharacteristic.manufacturerName)
    .subscribe(onNext: {
        let data = $0.value
    })
```

Set of methods that are taking instances conforming `CharacteristicIdentifier` or `DescriptorIdentifier` does all of the heavy lifting like discovering services, characteristics and descriptors for you. Moreover, in order to optimise - when one of these is available in cache, discovery is not called at all.
We really encourage you to use these versions of methods in order to make your code even shorter and cleaner.

### Other useful functionalities
Here you'll find other useful functionalities of library

#### Bluetooth state restoration
By giving proper identifier to `CentralManager` in constructor(`options` property), you can achieve state restoration functionality. Later, just make sure to subscribe to `listenOnRestoredState` observable, and inspect `RestoredState` instance, which consists any useful info about restored state.

#### Monitoring state of Bluetooth
Used earlier `observeState` is very useful function on `CentralManager`. It emits `next` event with new value of BluetoothManager state every time it changes. To get current bluetooth state, you should use `CentralManager.state`
property.

#### Monitor connection state of Peripheral
Property `isConnected` on `Peripheral` allows checking if Peripheral is connected. To monitor Peripheral connection state changes use `observeConnection` method. It emits new element after connection state changes.

#### Retrieving Peripherals
`CentralManager` also lets to retrieve peripherals in two ways:
- via its identifier using array of `UUID` objects,
- connected ones via services identifiers using array of `CBUUID` objects.
In both cases, return type is `[Peripheral]`.

#### Cancel connection
Connection can be cancelled. To do this dispose Disposable that you get during Peripheral connection.

#### Read RSSI
Triggers read of Peripheral RSSI value. To do it, call `readRSSI()` on Peripheral instance.
Method returns `Single<(Peripheral, Int)>`. Peripheral is returned in order to enable chaining.

#### Monitor services modification
When you want to know, when services are modified, call `observeServicesModification() -> Observable<(Peripheral, [Service])>` on Peripheral. Next event is generated each time, when service changes.

#### Monitor name update
Call `observeNameUpdate() -> Observable<(Peripheral, String?)>` in order to know, when peripheral changes its name.

#### Monitoring write
By calling `observeWrite(for characteristic: Characteristic) -> Observable<Characteristic>` you're able to receive event each time, when value is being written to characteristic.

### Additional features

#### Error bubbling
Library supports **complex** Bluetooth error handling functionalities. Errors from Bluetooth delegate methods are propagated into all of the API calls. So for example - if during services discovery bluetooth state changes to `.poweredOff`, proper error containing this information will be propagated into `discoverServices` call.

## Requirements
- iOS 8.0+
- OSX 10.10+
- watchOS 4.0+
- tvOS 11.0+
- Xcode 7.3+

## Authors

- Przemysław Lenart, przemek.lenart@polidea.com~
- Kacper Harasim, kacper.harasim@polidea.com



## Contributing
If you would like to contribute code you can do so through GitHub by forking the repository and sending a pull request.
To keep code in order, we advice you to use SwiftLint. In repository, we provide configured `.swiftlint.yml` file, that matches our criteria of clean and "Swifty" code.

### Contributors, thanks!

Maciek Oczko (maciek.oczko@polidea.com)

[moogle19](https://github.com/moogle19)
[abeintopalo](https://github.com/abeintopalo)

## License

RxBluetoothKit is available under the Apache License, Version 2.0. See the LICENSE file for more info.
