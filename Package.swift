// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "FreshchatSDK",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "FreshchatSDK",
            targets: ["FreshchatSDKTarget"]),
    ],
    targets: [
        .binaryTarget(
            name: "FreshchatSDKTarget",
            path: "FreshchatSDK.xcframework"
        ),
    ]
)
