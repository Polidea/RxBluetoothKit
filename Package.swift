// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxBluetoothKit",
    platforms: [
        .macOS(.v10_10), .iOS(.v8), .tvOS(.v11), .watchOS(.v4)
    ],
    products: [
        .library(name: "RxBluetoothKit", targets: ["RxBluetoothKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.1.1"))
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
