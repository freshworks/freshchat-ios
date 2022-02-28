// swift-tools-version:5.3
import PackageDescription
let package = Package(
    exclude: ["Sample"],
    name: "FreshchatSDK",
    platforms: [
        .iOS(.v9)
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
