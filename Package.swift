// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "RegulatoryCore",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "RegulatoryCore", targets: ["RegulatoryCore"]),
        .plugin(name: "RegulatoryCoreLicensePlugin", targets: ["RegulatoryCoreLicensePlugin"]),
    ],
    targets: [
        .binaryTarget(name: "RegulatoryCore", url: "https://github.com/darock-package-distribution/regulatorycore/releases/download/1.0.6/RegulatoryCore.xcframework.zip", checksum: "aeb121d1375a4e86cb9a620b5418ea7258f137926f00572a672d7e3f3d84fb1a"),
        .executableTarget(name: "RegulatoryCoreLicenseTool"),
        .plugin(
            name: "RegulatoryCoreLicensePlugin",
            capability: .buildTool(),
            dependencies: ["RegulatoryCoreLicenseTool"]
        ),
        .testTarget(
            name: "RegulatoryCoreLicenseToolTests",
            dependencies: ["RegulatoryCoreLicenseTool"]
        ),
    ]
)
