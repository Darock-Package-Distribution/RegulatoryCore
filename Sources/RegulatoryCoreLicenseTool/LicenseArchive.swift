internal import System
internal import Foundation
internal import AppleArchive

internal enum LicenseArchive {
    internal static func write(_ licenses: [LRCPackageLicense], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(licenses)
        let temporary = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try compress(data, to: temporary)
        let compressed = try Data(contentsOf: temporary)
        if (try? Data(contentsOf: url)) != compressed {
            try compressed.write(to: url, options: .atomic)
        }
    }
    
    private static func compress(_ data: Data, to url: URL) throws {
        guard let file = ArchiveByteStream.fileStream(
            path: .init(url.path),
            mode: .writeOnly,
            options: [.create, .truncate],
            permissions: [.ownerRead, .ownerWrite, .groupRead, .otherRead]
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { try? file.close() }
        guard let stream = ArchiveByteStream.compressionStream(using: .lzfse, writingTo: file) else {
            throw CocoaError(.fileWriteUnknown)
        }
        do {
            try data.withUnsafeBytes { buffer in
                var offset = 0
                while offset < buffer.count {
                    let count = try stream.write(from: .init(rebasing: buffer[offset...]))
                    guard count > 0 else { throw CocoaError(.fileWriteUnknown) }
                    offset += count
                }
            }
            try stream.close()
        } catch {
            try? stream.close()
            throw error
        }
    }
}
