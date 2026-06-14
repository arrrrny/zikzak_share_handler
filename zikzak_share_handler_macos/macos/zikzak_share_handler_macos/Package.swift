// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// This Package.swift provides Swift Package Manager support for zikzak_share_handler_macos.
// See: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors

import PackageDescription

let package = Package(
    name: "zikzak_share_handler_macos",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "zikzak-share-handler-macos",
            targets: ["zikzak_share_handler_macos"]),
        .library(
            name: "zikzak-share-handler-macos-models",
            type: .static,
            targets: ["zikzak_share_handler_macos_models"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "zikzak_share_handler_macos_models",
            dependencies: [],
            path: "Sources/zikzak_share_handler_macos_models"
        ),
        .target(
            name: "zikzak_share_handler_macos",
            dependencies: [
                "zikzak_share_handler_macos_models"
            ],
            path: "Sources/zikzak_share_handler_macos"
        ),
    ]
)
