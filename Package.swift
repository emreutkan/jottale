// swift-tools-version: 5.9
// SoulReaderApp — Swift Package Manifest
//
// NOTE: This manifest enables building and testing the non-UI service layer
// (ePubParserService, controllers, models) from the command line.
// The SwiftUI Views and iOS-specific frameworks (AVFoundation, UIKit) are
// intentionally excluded from the library target so the package compiles on
// macOS without a simulator.
//
// When adding the full app to Xcode, create an iOS App target and add all
// source files (including Views/) to that target.

import PackageDescription

let package = Package(
    name: "SoulReaderApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SoulReaderCore",
            targets: ["SoulReaderCore"]
        )
    ],
    dependencies: [
        // ZIPFoundation is used by ePubParserService to unzip .epub archives.
        .package(
            url: "https://github.com/weichsel/ZIPFoundation.git",
            from: "0.9.19"
        )
    ],
    targets: [
        .target(
            name: "SoulReaderCore",
            dependencies: ["ZIPFoundation"],
            path: "SoulReaderApp",
            exclude: [
                // SwiftUI views depend on UIKit / SwiftUI – compile in Xcode only.
                "Views",
                // App entry point requires @main and SwiftUI.App.
                "App",
                // Resources are embedded by Xcode, not SPM.
                "Resources"
            ],
            swiftSettings: [
                .define("SOUL_READER_CORE")
            ]
        ),
        .testTarget(
            name: "SoulReaderCoreTests",
            dependencies: ["SoulReaderCore"],
            path: "Tests/SoulReaderCoreTests"
        )
    ]
)
