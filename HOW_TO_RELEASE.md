
## Steps that needs to be done to release new version

- add new change log to `Changelog.md`
- change `RxBluetoothKit.podspec` with new library version
- generate new doc by running script `./scripts/generate-docs.sh x.x.x`
- push new commit with that changes
- create new release on github
- create archive by running `carthage build --no-skip-current && carthage archive RxBluetoothKit`
- add those archive to github release that was created before
- add library to cocoapods trunk by running: `pod trunk push RxBluetoothKit.podspec`
