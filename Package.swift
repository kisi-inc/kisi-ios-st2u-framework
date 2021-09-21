// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SecureUnlock",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SecureUnlock",
            targets: ["SecureUnlock"])
    ],
    targets: [
        .binaryTarget(
            name: "SecureUnlock",
            path: "SecureUnlock.xcframework"
        )
    ]
)
