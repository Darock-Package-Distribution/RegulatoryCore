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
        .binaryTarget(name: "RegulatoryCore", url: "https://github.com/darock-package-distribution/regulatorycore/releases/download/1.0.5/RegulatoryCore.xcframework.zip", checksum: "15f5e847887aede5baf3e7fdd0f85e9afacba633ab69c9082913ed449be82d8c"),
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
