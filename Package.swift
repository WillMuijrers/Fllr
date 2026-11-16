// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Fllr",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Fllr", path: "Sources/Fllr")
    ]
)
