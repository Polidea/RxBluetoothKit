#!/bin/sh

if [ "$1" == "iOS" ]; then
	set -o pipefail && xcodebuild test -verbose -scheme "RxBluetoothKit iOS" -destination "platform=iOS Simulator,OS=11.0,name=iPhone X" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "macOS" ]; then
	set -o pipefail && xcodebuild test -verbose -scheme "RxBluetoothKit macOS" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "tvOS" ]; then
	set -o pipefail && xcodebuild test -verbose -scheme "RxBluetoothKit tvOS" -destination "platform=tvOS Simulator,OS=11.0,name=Apple TV 4K" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "watchOS" ]; then
	echo "watchOS Unit Testing not yet available"
	exit 0
else
	echo "wrong parameters. (iOS|macOS|tvOS)"
	exit 1
fi
