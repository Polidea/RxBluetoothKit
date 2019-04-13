
## Steps that needs to be done to release new version

- add new change log to `Changelog.md`
- change `RxBluetoothKit.podspec` with new library version
- generate new doc by running script `./scripts/generate-docs.sh x.x.x`
- create archive by running `carthage build --no-skip-current && carthage archive RxBluetoothKit`
- create new Pull Request with that changes and merge it
- create new release on github and add archive previously created
- add library to cocoapods trunk by running: `pod trunk push RxBluetoothKit.podspec`
