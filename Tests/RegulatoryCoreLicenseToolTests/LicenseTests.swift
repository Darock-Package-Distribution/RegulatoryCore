internal import XCTest
internal import Foundation
@testable internal import RegulatoryCore
@testable internal import RegulatoryCoreLicenseTool

internal final class LicenseTests: XCTestCase {
    internal func testArchiveRoundTrip() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("LRCPLDefault.rclib")
        let licenses: [LRCPackageLicense] = [
            .init(id: "example", packageName: "Example", licenseName: "MIT", licenseContent: "License text — 许可证\n"),
            .init(id: "unknown", packageName: "Unknown", licenseName: nil, licenseContent: "Custom license")
        ]
        try LicenseArchive.write(licenses, to: url)
        XCTAssertEqual(try LRCPackageLicense.decodeLicenses(from: url), licenses)
        try LicenseArchive.write([], to: url)
        XCTAssertEqual(try LRCPackageLicense.decodeLicenses(from: url), [])
        try Data("invalid archive".utf8).write(to: url)
        XCTAssertThrowsError(try LRCPackageLicense.decodeLicenses(from: url))
        XCTAssertEqual(LRCPackageLicense.defaultLicenses(), [])
    }
    
    internal func testCollectsMultipleLicensesAndMissingLicense() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let licensed = directory.appendingPathComponent("Licensed")
        let missing = directory.appendingPathComponent("Missing")
        try FileManager.default.createDirectory(at: licensed, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: missing, withIntermediateDirectories: true)
        try "Permission is hereby granted, free of charge, to use this software".write(
            to: licensed.appendingPathComponent("LICENSE-MIT"), atomically: true, encoding: .utf8
        )
        try "Apache License\nVersion 2.0".write(to: licensed.appendingPathComponent("LICENSE-APACHE"), atomically: true, encoding: .utf8)
        let licenses = try LicenseCollector.collect([
            .init(id: "z-missing", name: "Missing", directory: missing.path),
            .init(id: "a-licensed", name: "Licensed", directory: licensed.path)
        ])
        XCTAssertEqual(licenses.map(\.id), ["a-licensed", "z-missing"])
        XCTAssertEqual(licenses[0].licenseName, "Apache-2.0 / MIT")
        XCTAssertTrue(licenses[0].licenseContent.contains("LICENSE-MIT"))
        XCTAssertTrue(licenses[0].licenseContent.contains("Version 2.0"))
        XCTAssertNil(licenses[1].licenseName)
        XCTAssertEqual(licenses[1].licenseContent, "")
    }
    
    internal func testReadmeAndSPDX() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try "# Example\n## License\nSPDX-License-Identifier: MIT OR Apache-2.0\n\n## Usage\nOther text".write(
            to: directory.appendingPathComponent("README.md"), atomically: true, encoding: .utf8
        )
        let licenses = try LicenseCollector.collect([.init(id: "example", name: "Example", directory: directory.path)])
        XCTAssertEqual(licenses[0].licenseName, "MIT OR Apache-2.0")
        XCTAssertFalse(licenses[0].licenseContent.contains("Other text"))
        XCTAssertNil(LicenseCollector.identify("Custom terms"))
        XCTAssertEqual(LicenseCollector.identify("Redistribution and use in source and binary forms. Neither the name"), "BSD-3-Clause")
    }
    
    private func temporaryDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("closure/\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
