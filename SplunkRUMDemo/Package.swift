// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SplunkRUMDemo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SplunkRUMDemo",
            targets: ["SplunkRUMDemo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/signalfx/splunk-otel-ios", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "SplunkRUMDemo",
            dependencies: [
                .product(name: "SplunkOtel", package: "splunk-otel-ios")
            ]
        )
    ]
)
