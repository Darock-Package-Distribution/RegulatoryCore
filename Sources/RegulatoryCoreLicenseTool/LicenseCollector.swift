internal import Foundation

internal struct PackageInput: Codable {
    internal let id: String
    internal let name: String
    internal let directory: String
    internal var isLocal = false
}

internal enum LicenseCollector {
    internal static func collect(_ packages: [PackageInput]) throws -> [LRCPackageLicense] {
        try packages.sorted { $0.id < $1.id }.compactMap { package -> LRCPackageLicense? in
            let root = URL(fileURLWithPath: package.directory)
            let files = try licenseFiles(in: root)
            guard !package.isLocal || !files.isEmpty else { return nil }
            var contents = try files.map { url in
                let content = try String(contentsOf: url, encoding: .utf8)
                return (url.lastPathComponent, content)
            }
            if contents.isEmpty, let readme = try readmeLicense(in: root) {
                contents = [("README", readme)]
            }
            if contents.isEmpty {
                FileHandle.standardError.write(Data("warning: No license found for \(package.name) (\(package.id)).\n".utf8))
            }
            let names = Set(contents.compactMap { identify($0.1) }).sorted()
            let content = contents.count == 1 ? contents[0].1 : contents.map {
                "===== \($0.0) =====\n\n\($0.1)"
            }.joined(separator: "\n\n")
            return .init(
                id: package.id,
                packageName: package.name,
                licenseName: names.isEmpty ? nil : names.joined(separator: " / "),
                licenseContent: content
            )
        }
    }
    
    internal static func licenseFiles(in root: URL) throws -> [URL] {
        let entries = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey]
        )
        var files: [URL] = []
        for entry in entries {
            let name = entry.lastPathComponent.lowercased()
            let values = try entry.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
            let isLicense = ["license", "licence", "copying", "copyright", "notice", "unlicense"].contains {
                name == $0 || name.hasPrefix($0 + ".") || name.hasPrefix($0 + "-") || name.hasPrefix($0 + "_")
            }
            if values.isRegularFile == true, isLicense {
                files.append(entry)
            } else if values.isDirectory == true, ["licenses", "licences", "legal"].contains(name) {
                let children = try FileManager.default.contentsOfDirectory(
                    at: entry,
                    includingPropertiesForKeys: [.isRegularFileKey]
                )
                files += try children.filter { try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true }
            }
        }
        return files.sorted { $0.path < $1.path }
    }
    
    internal static func identify(_ content: String) -> String? {
        if let range = content.range(of: #"SPDX-License-Identifier:\s*([^\r\n]+)"#, options: .regularExpression) {
            return content[range].components(separatedBy: ":").dropFirst().joined(separator: ":")
                .trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "*/>")))
        }
        let text = content.lowercased().replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        if text.contains("permission is hereby granted, free of charge"), text.contains("software") { return "MIT License" }
        if text.contains("apache license"), text.contains("version 2.0") { return "Apache-2.0" }
        if text.contains("mozilla public license"), text.contains("2.0") { return "MPL-2.0" }
        for (title, prefix) in [("gnu affero general public license", "AGPL"), ("gnu lesser general public license", "LGPL"), ("gnu general public license", "GPL")] {
            if text.contains(title) {
                let version = text.contains("version 3") ? "3.0" : text.contains("version 2.1") ? "2.1" : text.contains("version 2") ? "2.0" : nil
                if let version {
                    return "\(prefix)-\(version)-\(text.contains("any later version") ? "or-later" : "only")"
                }
            }
        }
        if text.contains("redistribution and use in source and binary forms") {
            if text.contains("all advertising materials") { return "BSD-4-Clause" }
            if text.contains("neither the name") { return "BSD-3-Clause" }
            return "BSD-2-Clause"
        }
        if text.contains("permission to use, copy, modify, and/or distribute this software for any purpose") { return "ISC" }
        if text.contains("this is free and unencumbered software released into the public domain") { return "Unlicense" }
        if text.contains("creative commons"), text.contains("cc0") { return "CC0-1.0" }
        if text.contains("boost software license"), text.contains("1.0") { return "BSL-1.0" }
        if text.contains("sil open font license"), text.contains("1.1") { return "OFL-1.1" }
        if text.contains("this software is provided 'as-is'"), text.contains("altered source versions") { return "Zlib" }
        return nil
    }
    
    private static func readmeLicense(in root: URL) throws -> String? {
        let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isRegularFileKey])
        for file in files.sorted(by: { $0.path < $1.path }) where file.lastPathComponent.lowercased().hasPrefix("readme") {
            guard try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true,
                  let content = try? String(contentsOf: file, encoding: .utf8),
                  let heading = content.range(of: #"(?im)^#{1,6}\s+licen[cs]e\s*#*\s*$"#, options: .regularExpression) else { continue }
            let remainder = content[heading.upperBound...]
            let end = remainder.range(of: #"(?m)^#{1,6}\s+"#, options: .regularExpression)?.lowerBound ?? remainder.endIndex
            let license = remainder[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            if !license.isEmpty { return license }
        }
        return nil
    }
}
