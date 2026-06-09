// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// This Package.swift provides Swift Package Manager support for zikzak_share_handler_ios.
// See: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors

import PackageDescription

let package = Package(
    name: "zikzak_share_handler_ios",
    platforms: [
        .iOS("15.6")
    ],
    products: [
        .library(
            name: "zikzak-share-handler-ios",
            targets: ["zikzak_share_handler_ios"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "zikzak_share_handler_ios_models",
            dependencies: [],
            path: "Sources/zikzak_share_handler_ios_models"
        ),
        .target(
            name: "zikzak_share_handler_ios",
            dependencies: [
                "zikzak_share_handler_ios_models"
            ],
            path: "Sources/zikzak_share_handler_ios"
        ),
    ]
)
