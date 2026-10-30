// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "SecureAccess",
    platforms: [
        .iOS(.v15)
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
