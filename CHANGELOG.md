
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
