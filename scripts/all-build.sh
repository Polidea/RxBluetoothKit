#!/bin/sh

if [ "$1" == "iOS" ]; then
	set -o pipefail && xcodebuild -verbose -schema "RxBluetoothKit iOS" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "macOS" ]; then
	set -o pipefail && xcodebuild -verbose -schema "RxBluetoothKit macOS" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "tvOS" ]; then
	set -o pipefail && xcodebuild -verbose -schema "RxBluetoothKit tvOS" ONLY_ACTIVE_ARCH=NO | xcpretty
elif [ "$1" == "watchOS" ]; then
	set -o pipefail && xcodebuild -verbose -schema "RxBluetoothKit watchOS" ONLY_ACTIVE_ARCH=NO | xcpretty
else
	echo "wrong parameters. (iOS|macOS|tvOS|watchOS)"
	exit 1
fi
