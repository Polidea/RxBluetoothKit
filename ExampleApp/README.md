ExampleApp shows most common, basic use cases of RxBluetoothKit. It's built with Catalyst, to provide the most real life experience even for those who currently don't own any BLE sensor to connect with. You just need an iOS device, and a mac computer to quickly see by yourself how to advertise services and characteristics, scan for peripherals, connect to them and observe the changes.

## Central mode

Central mode is show by two common use cases:
* `Specific`: Quickly [connect](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/CentralSpecific/CentralSpecificViewController.swift) to a specific peripheral, with known service and characteristic UUIDs and subscribe to changes of the value. BLE connection is done in a single Rx chain to show how easy and flexible RxBluetoothKit is. This screen also presents the desired way of ending a connection (see [here](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/CentralSpecific/CentralSpecificViewController.swift#L51))/
* `List`: List peripherals in range, connect to selected one, list it's services and characteristics and specifically [read](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/CharacteristicRead/CharacteristicReadViewController.swift), [subscribe to notifications](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/CharacteristicNotify/CharacteristicNotifyViewController.swift) or [write](https://github.com/Polidea/RxBluetoothKit/blob/new-example-app/ExampleApp/ExampleApp/Screens/CharacteristicWrite/CharacteristicWriteViewController.swift) to a characteristic. To show the best way of handling BLE in larger apps, we encapsulated connection logic in a separate object, a [BluetoothProvider](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/BluetoothProvider/BluetoothProvider.swift).

## Peripheral mode

Peripheral mode gives you the overview on how to advertise specific service with a specific characteristic for [update notifications](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/PeripheralUpdate/PeripheralUpdateViewController.swift), [reading](https://github.com/Polidea/RxBluetoothKit/ExampleApp/ExampleApp/Screens/PeripheralRead/PeripheralReadViewController.swift) and [writing](https://github.com/Polidea/RxBluetoothKit/blob/new-example-app/ExampleApp/ExampleApp/Screens/PeripheralWrite/PeripheralWriteViewController.swift) to said characteristic.

## Requirements
* Xode 12.0

## Installation

1. Open up `ExampleApp.xcodeproj` in Xcode and give some time to SPM to set up dependencies.
2. In `Signing & Capabilities` set team for iOS distribution to your "personal team".
3. Run the project on "My Mac" target
4. Without stopping the project, run again on iOS device.
5. Enjoy BLE connection between your device and your mac 🎉