// swift-tools-version:5.9
// This Package.swift is for CLI validation only. Use the .xcodeproj for the full app.
import PackageDescription

let package = Package(
    name: "AppleML",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
    ],
    targets: [
        .executableTarget(
            name: "AppleML",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ],
            path: "AppleML"
        ),
    ]
)
