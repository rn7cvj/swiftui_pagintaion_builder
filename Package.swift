// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swiftui_pagintaion_builder",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftUIPagintaionBuilder",
            targets: ["SwiftUIPagintaionBuilder"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIPagintaionBuilder",
            path: "Sources/SwiftUIPagintaionBuilder"
        )
    ]
)
