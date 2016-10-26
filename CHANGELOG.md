
# 3.0.5
- Fixed bug when `options` dictionary was not being passed to `BluetoothManager` when initializing it
- Updated README.md to use `Observable.from` in correct way

# 3.0.4
- Updated RxSwift dependency version to 3.0.0
- Updated Nimble dependency version to 5.1

# 3.0.3
- Updated RxSwift dependency version to 3.0.0-rc.1

# 3.0.2
- Updated RxSwift dependency version to 3.0.0-beta.2

# 3.0.1
- Fixed support for Cocoapods

# 3.0.0
- Implemented compatibility for Swift 3.0. This includes adoption of Swift Design Guidelines and new Value Types in Cocoa.
- Implemented function `maximumWriteValueLength` on `Peripheral` instance that is available from OSX 10.12 and iOS 9.0
- Couple of minor code cleanups in order to make source more concise and easier to read

# 2.0.0
- Implemented compatibility for Swift 2.3. This version is supposed to work with Xcode 7.3 and Xcode 8.
- Introduced `BluetoothState` which is same as `CBCentralManagerState` and `CBManagerState` and help us achieve compatibility with 8.0 and 10.0 CoreBluetooth SDKs.
- Removed deprecated methods from earlier versions - `monitorState` and `monitorStateChange` from `BluetoothManager`
- Removed method `rx_state` on `Peripheral` instance. It didn't work well and you should use `rx_isConnected` instead.
- Removed method `monitorPeripheralDisconnection`. You should use `rx_isConnected` instead

# 1.2.4
- Removed `platform` specifier from podpspec

# 1.2.3
- Bubbling of errors added to `monitorPeripheralDisconnection` method

# 1.2.2
- Fixed memory leak, that was visible while calling scan
- Fixed behavior of discoverServices method.
- Added monitoring of disconnection on Peripheral example to the Example app
# 1.2.1 
- `listenOnRestoredState` method made public

# 1.2.0
- Added support for Core Bluetooth state restoration

# 1.1.1
- Fixed a bug regarding `rx_state` behavior

# 1.1.0

- New API in `BluetoothManager`: `rx_state` to monitor `CBCentralManager` state changes
- New API in `Peripheral`: `rx_state` to monitor `CBPeripheral` state change and `rx_isConntected` to monitor connection state changes
- `monitorState()` and `monitorStateChange()` marked as deprecated
- Added dependency for RxCocoa

# 1.0.1


- Fixed issues related to scan sharing


# 1.0.0


- Added OSX support. Official 1.0 release


# 0.4.1


- Fixed possible race condition in `setNotifyAndMonitor` function


# 0.4.0

- Documentation updated
- Use cases added to example app
- Added convenience methods to peripheral
- Added protocols that are giving user access to convenience API.


# 0.3.7


- Improved APIs of `Characteristic` and `Service`


# 0.3.5-0.3.6

- Added convenience methods to `Peripheral`. Check more about it in README.

# 0.3.4

- Deleted jazzy.yaml in order to make cocoadocs work

# 0.3.3
- Initial release
