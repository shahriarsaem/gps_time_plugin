// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gps_time_plugin",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "gps-time-plugin", targets: ["gps_time_plugin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "gps_time_plugin",
            dependencies: [],
            path: "Sources/gps_time_plugin",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"]),
            ]
        ),
    ]
)
