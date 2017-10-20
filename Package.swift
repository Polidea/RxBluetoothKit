// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxBluetoothKit",
    products: [
        .library(name: "RxBluetoothKit", targets: ["RxBluetoothKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
                name: "RxBluetoothKit",
                dependencies: [
                    "RxSwift"
                ],
                path: ".",
                exclude: [
                    "Example",
                    "Tests"
                ],
                sources: [
                    "Source"
                ]
            )
    ]
)
