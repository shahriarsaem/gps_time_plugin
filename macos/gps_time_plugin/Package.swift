// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "gps_time_plugin",
    platforms: [
        .macOS("10.14"),
    ],
    products: [
        .library(name: "gps-time-plugin", targets: ["gps_time_plugin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "gps_time_plugin",
            dependencies: [],
            path: "Sources/gps_time_plugin"
        ),
    ]
)
