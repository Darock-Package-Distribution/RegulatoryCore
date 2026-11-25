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
        .binaryTarget(name: "RegulatoryCore", url: "https://github.com/darock-package-distribution/regulatorycore/releases/download/1.0.7/RegulatoryCore.xcframework.zip", checksum: "d33dc46a67306301d6f031cf9dd0eb97f1fb75648b256d4f4f60c66d1861c16c"),
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
