// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "FreshchatSDK",
    platforms: [
        .iOS(.v8)
    ],
    targets: [
        .binaryTarget(
            name: "FreshchatSDKTarget",
            path: "FreshchatSDK.xcframework"
        )
    ]
)
