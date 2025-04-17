// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SecureAccess",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SecureAccess",
            targets: ["SecureAccess"])
    ],
    targets: [
        .binaryTarget(
            name: "SecureAccess",
            path: "SecureAccess.xcframework"
        )
    ]
)
