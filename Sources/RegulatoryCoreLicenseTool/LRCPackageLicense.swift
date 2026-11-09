internal import Foundation

// Keep this serialized schema aligned with RegulatoryCore.LRCPackageLicense.
internal struct LRCPackageLicense: Codable, Equatable {
    internal var id: String
    internal var packageName: String
    internal var licenseName: String?
    internal var licenseContent: String
}
