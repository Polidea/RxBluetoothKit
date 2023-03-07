// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxBluetoothKit_Airthings",
    platforms: [
        .macOS(.v10_13), .iOS(.v9), .tvOS(.v11), .watchOS(.v4)
    ],
    products: [
        .library(name: "RxBluetoothKit_Airthings", targets: ["RxBluetoothKit_Airthings"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.5"))
    ],
    targets: [
        .target(
                name: "RxBluetoothKit_Airthings",
                dependencies: [
                    "RxSwift"
                ],
                path: ".",
                exclude: [
                    "Example",
                    "Tests",
                    "Source/Info.plist",
                    "Source/RxBluetoothKit.h"
                ],
                sources: [
                    "Source"
                ]
            )
    ]
)
