// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "FreshchatSDK",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "FreshchatSDK",
            targets: ["FreshchatSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "FreshchatSDK",
            path: "FreshchatSDK.xcframework"
        ),
    ]
)
