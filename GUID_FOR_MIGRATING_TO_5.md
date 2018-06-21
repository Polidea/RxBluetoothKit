# Guide for migrating to `RxBluetothKit` 5

### What has changed?

`RxBlutoothKit` starting from version 5.0.0 changes a lot in API. Here is a list of main changes that occured:

- `BluetoothManager` renamed to `CentralManager` - with this change we have unified naming with `CoreBluetooth`. This change also gives us possibility to add easily `PeripheralManager` support.
- Changed returns from `Observable<>` to `Single` where applies.
- Removed `BluetoothManager.listenOnRestoredState` and instead of this added new `CentralManager.init(queue: DispatchQueue, options: [String: AnyObject]?, onWillRestoreState: OnWillRestoreState?)` initializer
- removed support for calling `CentralManager.scanForPeripherals` when scanning is ongoing. Before we were doing queuing or sharing of new call but we had numerous issues with such approach. From now on, if there is ongoing scan `Observable` will immediately finish with `BluettothError.scanInProgress` error.
- `BluetoothManager.rx_state` renamed to `CentralManager.observeState`. In addition to it `CentralManager.observeState` is no more starting with current state value.
- `BluetoothManager.connect` renamed to `CentralManager.establishConnection`. Removed `BluetoothManager.cancelPeripheralConnection` and `Peripheral.cancelConnection`. We have changed way of connecting to peripheral in more reactive way. `CentralManager.establishConnection` is now also canceling connection on it's dispose. Due to that chanes it is now not possible to call `CentralManager.establishConnection` on device that is already connected (the only exception of this behaviour is for devices that we get from state restoration).
- `CentralManager.retrieveConnectedPeripherals` and `CentralManager.retrievePeripherals` are now returning `[Peripheral]` instead of `Observable<[Peripheral]>`.
- `BluetoothManager.monitorConnection` renamed to `CentralManager.observeConnect`.
- `BluetoothManager.monitorDisconnection` renamed to `CentralManager.observeDisconnect`.
- all `Peripheral.monitorWrite` methods renamed to `Peripheral.observeWrite`.
- all `Peripheral.monitorValueUpdate` methods renamed to `Peripheral.observeValueUpdate`.
- `Peripheral.monitorNameUpdate` renamed to `Peripheral.observeNameUpdate`.
- `Peripheral.monitorServicesModification` renamed to `Peripheral.observeServicesModification`.
- `Peripheral.observeValueUpdateAndSetNotification` added, `Peripheral.setNotifyValue` and `Peripheral.setNotificationAndMonitorUpdates` removed. From now on is seting notificaiton on subscription and unseting it on disposing. In addition it is possible to set more observables for same characteristic - it will work in a way that dispose will only happen when there are no observables for characteristic.


### Diffs on `README.md` file

```swift
-let stateObservable = manager.rx_state
+let stateObservable = manager.observeState()
```

```swift
-manager.rx_state
+manager.observeState()
+	.startWith(manager.state)
 	.filter { $0 == .poweredOn }
 	.timeout(3.0, scheduler)
 	.take(1)
-	.flatMap { manager.scanForPeripherals(withServices: [serviceId]) }
+	.flatMap { _ in manager.scanForPeripherals(withServices: [serviceId]) }
```

```swift
 manager.scanForPeripherals(withServices: [serviceId]).take(1)
-	.flatMap { $0.peripheral.connect() }
+	.flatMap { $0.peripheral.establishConnection() }
 	.subscribe(onNext: { peripheral in
 		print("Connected to: \(peripheral)")
 	})
```

```swift
-peripheral.connect()
-	.flatMap { $0.discoverServices([serviceId]) }
+peripheral.establishConnection()
+	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
 	.flatMap { Observable.from($0) }
```

```swift
-peripheral.connect()
-	.flatMap { $0.discoverServices([serviceId]) }
+peripheral.establishConnection()
+	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
 	.flatMap { Observable.from($0) }
-	.flatMap { $0.discoverCharacteristics([characteristicId])}
+	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
 	.flatMap { Observable.from($0) }
```

```swift
-peripheral.connect()
-	.flatMap { $0.discoverServices([serviceId]) }
+peripheral.establishConnection()
+	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
 	.flatMap { Observable.from($0) }
-	.flatMap { $0.discoverCharacteristics([characteristicId])}
+	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
 	.flatMap { Observable.from($0) }
```

```swift
-characteristic.setNotificationAndMonitorUpdates()
+let disposable = characteristic.observeValueUpdateAndSetNotification()
 	.subscribe(onNext: {
 		let newValue = $0.value
 	})
```

```swift
-characteristic.setNotifyValue(false)
-	.subscribe(onNext: { characteristic in
-		//Notification are now disabled.
-	})
+disposable.dispose()
```

 ```swift
-peripheral.connect()
-    .flatMap { Observable.from($0.discoverServices([serviceId])) }
-    .flatMap { Observable.from($0.discoverCharacteristics([characteristicId])}
-    .flatMap { $0.readValue }
-    .subscribe(onNext: {
-        let data = $0.value
-    })
+peripheral.establishConnection()
+	.flatMap { $0.discoverServices([serviceId]) }.asObservable()
+	.flatMap { Observable.from($0) }
+	.flatMap { $0.discoverCharacteristics([characteristicId])}.asObservable()
+	.flatMap { Observable.from($0) }
+	.flatMap { $0.readValue() }
+	.subscribe(onNext: {
+		let data = $0.value
+	})
 ```