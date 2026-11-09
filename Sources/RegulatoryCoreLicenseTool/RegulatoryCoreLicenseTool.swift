internal import Foundation

@main
internal struct RegulatoryCoreLicenseTool {
    internal static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 3 else {
            throw ToolError.invalidArguments
        }
        let packages = try JSONDecoder().decode([PackageInput].self, from: Data(arguments[1].utf8))
        let output = URL(fileURLWithPath: arguments[2])
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try LicenseArchive.write(LicenseCollector.collect(packages), to: output)
    }
    
    private enum ToolError: Error {
        case invalidArguments
    }
}
