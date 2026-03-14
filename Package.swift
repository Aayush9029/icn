// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "icn",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "icn", targets: ["icn"]),
        .library(name: "ICNKit", targets: ["ICNKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "icn",
            dependencies: [
                "ICNKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(name: "ICNKit"),
        .testTarget(
            name: "ICNKitTests",
            dependencies: ["ICNKit"]
        ),
    ]
)
