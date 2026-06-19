// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SocialFeedCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SocialFeedCore", targets: ["SocialFeedCore"])
    ],
    targets: [
        .target(
            name: "SocialFeedCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SocialFeedCoreTests",
            dependencies: ["SocialFeedCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
