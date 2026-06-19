// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SocialFeedFirebase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SocialFeedFirebase", targets: ["SocialFeedFirebase"])
    ],
    dependencies: [
        .package(path: "../SocialFeedCore"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "SocialFeedFirebase",
            dependencies: [
                .product(name: "SocialFeedCore", package: "SocialFeedCore"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
