// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MovieBrowserCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MovieBrowserCore", targets: ["MovieBrowserCore"])
    ],
    dependencies: [
        .package(path: "../NetworkKit"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MovieBrowserCore",
            dependencies: [
                .product(name: "NetworkKit", package: "NetworkKit")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MovieBrowserCoreTests",
            dependencies: [
                "MovieBrowserCore",
                .product(name: "Clocks", package: "swift-clocks")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
