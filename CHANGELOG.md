# 7.0.0
- Updated RxSwift version to 6.0 (#392)

# 6.0.0
- Increased deployment target for iOS to 9.0 and for osx to 10.13 (#379, #380)
- Added support for observing ancsAuthorized property on peripheral. (#370)
- Added Bluetooth usage description to Info.plist in Example project (#369)
- Added initial state improvement & a minor fix for BluetoothState methods. (#371)
- Fixed problems with SPM support (#358, #368)
- Updated RxSwift version to 5.1 (#376)
- Updated project configurations to decrease build time on TravisCI (#376)
- Updated scripts to fixed problems with generating mocks (#378)

# 5.3.0
- Always connect to retrieved peripherals first (#337)
- Addded a customisation point for injecting a logger (#341)
- Fixed L2CAP API to support OSX 10.14 (#345)

# 5.2.1
- Updated RxSwift to version 5.0 (#335)

# 5.2.0
- Added support for Xcode 10.2 and Swift 5 (#321)
- Fixed "API MISUSE" after canceling notification state when bluetooth is powered off (#319)
- Fixed problems when `discoverServices` doesn't emit any result (#309)

# 5.1.4
- Updated RxSwift library to version 4.3
- fix API MISUSE when calling stop scan on dispose (#283)
- add option to disable checking of canSendWriteWithoutReponse while writing (#282)

# 5.1.3
- Changed back deployment target from 10.0 to 8.0. (#275)

# 5.1.2
- Updated RxSwift to 4.2 with support for XCode 9.4 (#268)

# 5.1.1
- Fixed `PeripheralManager` not public (#264)

# 5.1.0
- Added support for `CBPeripheralManager`. Read `PeripheralManager` documentation for more info (#166)
- Deprecated `RestoredState` and `CentralManager.init(queue:options:onWillRestoreCentralManagerState:)`. From now on please use corresponding `CentralManagerRestoredState` and `CentralManager.init(queue:options:onWillRestoreCentralManagerState:)`

# 5.0.2
- Changed error name from `BluetoothError.peripheralIsConnectingOrAlreadyConnected` to `BluetoothError.peripheralIsAlreadyObservingConnection` - old error has been deprecated (#245)
- To each method, that returns observable, added documentation with a list of errors that this observable can return (#225)
- Rewritten example app that is now using RxBluetoothKit 5.x (#240, #220)
- Added available annotation for `canSendWriteWithoutResponse` property (#253)

# 5.0.1
- Added method to observe notyfing state change for the characteristic (#229)
- Aligned the API for `establishConnection` with the rest of the implementation
- Made restore state api public (#224)
- Enabled getting an `Observable<Peripheral>` from already connected peripheral provided by the system (#238)
- Fixed writting without response on older systems (#241)
- Added queues for discovery requests (fixed #235)
- Added support for XCode 9.3 and swift 4.1

# 5.0
- Changed `BluetoothManager` to `CentralManager`
- Reimplemented connection and notification API's
- Added watchOS and tvOS targets
- Added support for L2CAP
- Rewritten unit tests

# 4.0.2
- Allow projects that depend on RxBluetoothKit to update RxSwift to 4.1.0 and newer.

# 4.0.1
- Add missing logs for CBPeripheral and CBCentralManager classes.
- Fixed implementation of scanning subscription queue.

# 4.0
- App updated to newest iOS & macOS SDK
- Swift 4 adoption
- Possible memory leaks removed

# 3.1.2
- Fix building on macOS with the newest SDK

# 3.1.1
- `listenedOnRestoredState` should not be missing events from delegate now in case of race condition
- Fixed build issue caused by swiftlint

# 3.1
- Access from library objects to `CBCentralManager` and `Peripheral` instances is now public
- Fixed a bug regarding doing unnecessary operations when peripheral was disconnected

# 3.0.14
- Fixed building on Xcode 9 Beta 2

# 3.0.13
- Small changes to printing optionals, due to Swift warnings

# 3.0.12
- Added option to enable logging of CoreBluetooth delegate values
  used internally by RxBluetoothKit
- Make objectId fields public for Service, Characteristic and Descriptor classes.

# 3.0.11
- Updated podspec file to proper version.

# 3.0.10
- Added objectId property to missing `Service`, `Characteristic` and `Descriptor` objetcs.

# 3.0.9
- Added objectId property to `Peripheral` object needed by react-native library. Should not be necessary in 4.x version of the library. 

# 3.0.8
- Support for multiple services/characteristics under the same UUID

# 3.0.7
- Updated RxSwift dependency version to 3.2.0
- Some small code cleanups

# 3.0.6
- Fixed SwiftLint & Xcode warnings
- Updated swift-version in `jazzy.yml` file to allow cocoadocs parsing

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
