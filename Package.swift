// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swiftui_pagination_builder",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftUIPaginationBuilder",
            targets: ["SwiftUIPaginationBuilder"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIPaginationBuilder",
            path: "Sources/SwiftUIPaginationBuilder"
        )
    ]
)
