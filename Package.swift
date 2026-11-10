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
        .binaryTarget(name: "RegulatoryCore", url: "https://github.com/darock-package-distribution/regulatorycore/releases/download/1.0.3/RegulatoryCore.xcframework.zip", checksum: "c65ba073be7061d46e811a04b8741170e9395488c88bd86830a9a59daf3cf80f"),
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
