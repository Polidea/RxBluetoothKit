# RxBluetoothKit

[![CI Status](http://img.shields.io/travis/Przemysław Lenart/RxBluetoothKit.svg?style=flat)](https://travis-ci.org/Przemysław Lenart/RxBluetoothKit)
[![Version](https://img.shields.io/cocoapods/v/RxBluetoothKit.svg?style=flat)](http://cocoapods.org/pods/RxBluetoothKit)
[![License](https://img.shields.io/cocoapods/l/RxBluetoothKit.svg?style=flat)](http://cocoapods.org/pods/RxBluetoothKit)
[![Platform](https://img.shields.io/cocoapods/p/RxBluetoothKit.svg?style=flat)](http://cocoapods.org/pods/RxBluetoothKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

RxBluetoothKit is an Bluetooth library that makes interaction with BLE devices much more pleasant. It's backed by RxSwift and CoreBluetooth.
Provides nice API to work with, and makes your code more readable, reliable and easier to maintain.

For support head to [StackOverflow](http://stackoverflow.com/questions/tagged/rxandroidble?sort=active), or open [an issue](https://github.com/Polidea/RxAndroidBle/issues/new) on Github.

## Features
- [x] CBCentralManger RxSwift support
- [x] CBPeripheral RxSwift support
- [x] Scan sharing
- [x] Scan queueing
- [x] Bluetooth error bubbling
- [x] Documentation // TODO: Link to cocoadocs.


## Sample
In Example folder you can find application we've provided to you. It's a great place to dig in, once you want to see everything in action. App provides most of the common usages of RxBluetoothKit.

## Installation

RxBluetoothKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RxBluetoothKit"
```



## Architecture
Library is built on top of Apple's CoreBluetooth.
It has multiple components, that should be familiar to you:

- BluetoothManager
- ScannedPeripheral
- Peripheral
- Service
- Characteristic
- Descriptor

Every one of them is backed by it's CB counterpart hidden behind layer of abstraction. We've chosen this architecture, because we believe in *testing*.

## Usage

To begin work you should create an instance of BluetoothManager. Doing it is really easy - all you need to specify is queue(main queue is used by default):
```swift
let manager = BluetoothManager(queue: dispatch_get_main_queue())
```
You are responsible for maintaining instance of manager object, and passing it between parts of your app.
**Note:** All operations are executed in queue which you have provided, so make sure to observe UI related effects in main thread when it's needed.

### Scanning peripherals
To start any interaction, with bluetooth devices, you have to first scan some of them. So - get ready!
#### Basic
```
manager.scanForPeripherals([serviceIds])
	.flatMap { scannedPeripheral
		let advertisement = scannedPeripheral.advertisement
	}
```
This is the simplest version of this operation. After subscription to observable, scan is performed infinitely.  What you receive from method is ScannedPeripheral instance, that provides access to following information:
- Peripheral: object that you can use, to perform actions like connecting, discovering services etc.
- AdvertisementData: strongly typed wrapper around CBPeripheral advertisement data dictionary.. Thanks to it, you no longer have to worry about all of the keys needed to pull out information.
- RSSI

#### Cancelling
By default scanning operation is not cancelled. It's the user's responsibility to do that in situations where scanning in not needed anymore.
Fortunately, this is also really easy to do, thanks to awesome RxSwift operators.
```
manager.scanForPeripherals([serviceIds]).take(1) //Doing this, after first received result, scan is immediately cancelled.
```
Ok, that's fun, but what if you also want to apply timeout policy? That's also easy to do:
```
manager.scanForPeripherals([serviceIds]).timeout(3.0, timerScheduler)
```

As you can see: thanks to all available RxSwift operators, in a simple way you might create really interesting and complex usage scenarios, like for example retrying scans, if you receive timeout.

#### Waiting for proper BluetoothState
In a following scenario: just after app launch, you want to perform scans. But, there are some problems with this approach - in order to perform work with bluetooth, you're manager should be in **.PoweredOn** state. Specially for this case, our library provides you with another observable, that you should use for monitoring state.
```
/* After subscribe, this observable will immediately emit next event with current value of BluetoothManager state, and later will fire every time state changes
*/
let monitorState = manager.monitorState()
```
You could easily chain it with operation you want to perform after changing to proper state. Let's see how it looks with scanning:
```
/*Firstly, filter .PoweredOn from states stream. Like above, we want to apply timeout policy to state changes. Also, we use **take** to be sure, that after getting .PoweredOn state, nothing else ever will be emitted by the observable.
*/
manager.monitorState()
.filter { $0 == .PoweredOn }
.timeout(3.0, scheduler)
.take(1)
//We received proper state, let's do some action!
.flatMap { manager.scanForPeripherals([serviceId]) }
```

### Connecting
After receiving scanned peripheral, to do something with it, we need to first call connect.
It's really straightforward: just flatMap result into another Observable!
```swift
manager.scanForPeripherals([serviceId]).take(1)
	.flatMap { $0.peripheral.connect() }
	.flatMap { //Peripheral is now connected and ready }
```

### Discovering services
After connecting, the most common task is to discover Services.
Because all of wanted services are discovered at once, method returns `Observable<[Service]>`.  In order to make it into `Observable<Service>` and fire for each of service discovered, we advice you to use our RxSwift operator `Observable.from()`

Here's how it works in RxBluetoothKit:
```swift
peripheral.connect()
.flatMap { Observable.from($0.discoverServices([serviceId])) }
.flatMap { //Discovered service is ready to work with }
```

### Discovering characteristics
Discovering characteristics method is very similar to **discoverServices**.
This time API's returning `Observable<[Characteristic]>` and to process one
characteristic at a time, you need to once again use `Observable.from()`
```swift
peripheral.connect()
.flatMap { Observable.from($0.discoverServices([serviceId])) }
.flatMap { Observable.from($0.discoverCharacteristics([characteristicId])}
```

### Reading value of characteristic
Once you've got characteristic, next common step is to read value from it.
In order to do that, you should use `readValue()` function defined on `Characteristic`. It returns `Observable<Characteristic>` which emits element, when value of characteristic is ready to read.
We decided to return `Characteristic` instead of `NSData` due to one purpose - to allow you chain operations on characteristic in easy way.
```swift
peripheral.connect()
.flatMap { Observable.from($0.discoverServices([serviceId])) }
.flatMap { Observable.from($0.discoverCharacteristics([characteristicId])}
.flatMap { $0.readValue }
.subscribeNext {
	let data = $0.value
}
```

### Notifying on characteristic changes
Notifying on characteristic value changes? Nothing easier.
First, you should set notify on characteristic on true. Later, just call monitoring on characteristic and you're ready to go!
```swift
characteristic.setNotifyValue(true)
.flatMap { $0.monitorValueUpdate() }
.subscribeNext {
	let newValue = $0.value
}
```

### Writing value to characteristic
While deciding to write to characteristic you have two writing options, that determine write behavior:
- WithResponse
- WithoutResponse

Choosing `WithResponse`, you're waiting to receive .Next event on Observable while device has confirmed that value has been written to it. Also, if any error has ocurred - you will receive `.Error` on Observable.
On the other hand - if you decided to go with `WithoutResponse` - you're receiving Characteristic just after write command has been called. Also, no errors will be emitted.
Let's jump over to the code:
```swift
characteristic.writeValue(data, type: .WithResponse)
.subscriben { event in
	//respond to errors / successful read
}
```


### Other useful functionalities
Here you'll find other useful functionalities of library

#### Monitoring state
Used earlier `monitorState()` is very useful function on `BluetoothManager`. While subscribed, it emits .Next immediately with current `CBCentralManagerState`.
After that, it emits new element after state changes.

#### Retrieving Peripherals
`BluetoothManager` also lets to retrieve peripherals in two ways:
- via its identifier using array of `NSUUID` objects,
- connected ones via services identifiers using array of `CBUUID` objects.
In both cases, return type is `Observable<[Peripheral]>`, which emits .Next, and after that immediately .Complete is received.

#### Cancel connection
Connection can be cancelled - just use `cancelConnection` method on `Peripheral`, or `BluetoothManager`.
Emits next, while disconnection confirmation is received.

#### Read RSSI
Triggers read of Peripheral RSSI value. To do it, call `readRSSI()` on Peripheral instance.
Method returns `Observable<Peripheral, Int>`. Peripheral is returned in order to enable chaining.

#### Monitor services modification
When you want to know, when services are modified, call `monitorServicesModification() -> Observable<(Peripheral, [Service])>` on Peripheral. Next event is generated each time, when service changes.

#### Monitor name update
Call `monitorUpdateName() -> Observable<(Peripheral, String?)>` in order to know, when peripheral changes its name.

#### Monitoring write
By calling `monitorWriteForCharacteristic(characteristic: Characteristic) -> Observable<Characteristic>` you're able to receive event each time, when value is being written to characteristic.



### Additional features

#### Scan sharing & queueing
Library supports scan sharing, which helps if you want to perform multiple scans at once in your application.
Thanks to that, if you want to perform scan B, while scan A is in progress, if your identifiers used to start scan B are subset of identifiers used by scan A - scan is shared.
Also, thanks to queueing, if it's not subset - it'll be queued until scan A will be stopped.

#### Error bubbling
Library supports **complex** Bluetooth error handling functionalities. Errors from Bluetooth delegate methods are propagated into all of the API calls. So for example - if during services discovery bluetooth state changes to `.PoweredOff`, proper error containing this information will be propagated into `discoverServices` call.


## Requirements
- iOS 8.0+
- Xcode 7.3+

## Authors

- Przemysław Lenart, przemek.lenart@polidea.com
- Kacper Harasim, kacper.harasim@polidea.com

## Contributing
If you would like to contribute code you can do so through GitHub by forking the repository and sending a pull request.
To keep code in order, we advice you to use SwiftLint. In repository, we provide configured .swiftlint.yml file, that matches our criteria of clean and "Swifty" code.  

## License

RxBluetoothKit is available under the MIT license. See the LICENSE file for more info.
