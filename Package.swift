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
        .binaryTarget(name: "RegulatoryCore", url: "", checksum: ""),
        .executableTarget(name: "RegulatoryCoreLicenseTool", dependencies: ["RegulatoryCore"]),
        .plugin(
            name: "RegulatoryCoreLicensePlugin",
            capability: .buildTool(),
            dependencies: ["RegulatoryCoreLicenseTool"]
        ),
        .testTarget(
            name: "RegulatoryCoreLicenseToolTests",
            dependencies: ["RegulatoryCore", "RegulatoryCoreLicenseTool"]
        ),
    ]
)
