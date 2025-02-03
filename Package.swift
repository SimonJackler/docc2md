// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "docc2md",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "docc2md", targets: ["docc2md"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        .executableTarget(name: "docc2md")
    ]
)
