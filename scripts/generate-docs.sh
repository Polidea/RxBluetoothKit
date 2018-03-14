#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

cd ..

LIBRARY_VERSION="$1"

if [ -z "$LIBRARY_VERSION" ]; then
	echo "Please specify library version to compile (e.g. 4.0.2):"
	read LIBRARY_VERSION
	if [ -z "$LIBRARY_VERSION" ]; then
		echo "Library version not specified!"
		exit 1
	fi
fi


jazzy \
	--github-file-prefix https://github.com/Polidea/RxBluetoothKit/tree/${LIBRARY_VERSION} \
	--module-version ${LIBRARY_VERSION}

