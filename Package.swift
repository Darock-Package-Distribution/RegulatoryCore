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
        .binaryTarget(name: "RegulatoryCore", url: "https://github.com/darock-package-distribution/regulatorycore/releases/download/1.0.1/RegulatoryCore.xcframework.zip", checksum: "781ff82c27cbad69b64504baf2a583479335e953d0cd638858dcb847ac18608e"),
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
