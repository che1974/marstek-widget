// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MarstekWidget",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MarstekWidget",
            path: "Sources/MarstekWidget"
        )
    ]
)
