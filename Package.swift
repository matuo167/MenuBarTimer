// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuBarTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MenuBarTimer", targets: ["MenuBarTimer"])
    ],
    targets: [
        .executableTarget(name: "MenuBarTimer")
    ]
)
