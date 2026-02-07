// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GherkinGenerator",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .macCatalyst(.v17)
    ],
    products: [
        .library(
            name: "GherkinGenerator",
            targets: ["GherkinGenerator"]
        )
    ],
    targets: [
        .target(
            name: "GherkinGenerator",
            path: "Sources/GherkinGenerator",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GherkinGeneratorTests",
            dependencies: ["GherkinGenerator"],
            path: "Tests/GherkinGeneratorTests"
        )
    ]
)
