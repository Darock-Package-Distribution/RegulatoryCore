internal import Foundation
internal import PackagePlugin
#if canImport(XcodeProjectPlugin)
internal import XcodeProjectPlugin
#endif

@main
internal struct RegulatoryCoreLicensePlugin: BuildToolPlugin {
    internal func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        var packages: [String: PackageInput] = [:]
        var visited = Set<String>()
        func visit(_ package: Package) {
            guard visited.insert(package.id).inserted else { return }
            package.dependencies.forEach { visit($0.package) }
            if case .repository(let url, _, _) = package.origin, isExcludedRepository(url) {
                return
            }
            packages[package.id] = .init(
                id: package.id,
                name: package.displayName,
                directory: package.directoryURL.path
            )
        }
        context.package.dependencies.forEach { visit($0.package) }
        return try commands(
            packages: Array(packages.values),
            tool: context.tool(named: "RegulatoryCoreLicenseTool").url,
            workDirectory: context.pluginWorkDirectoryURL
        )
    }
    
    private func isExcludedRepository(_ location: String) -> Bool {
        let location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: "git@github.com:",
                with: "https://github.com/",
                options: [.anchored, .caseInsensitive]
            )
        guard let url = URL(string: location),
              url.host?.lowercased() == "github.com",
              let owner = url.path.split(separator: "/").first?.lowercased() else {
            return false
        }
        return ["darock-package-distribution", "darock-studio"].contains(owner)
    }
    
    private func commands(
        packages: [PackageInput],
        tool: URL,
        workDirectory: URL,
        extraInputs: [URL] = []
    ) throws -> [Command] {
        let packages = packages.sorted { $0.id < $1.id }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(packages)
        let output = workDirectory.appendingPathComponent("LRCPLDefault.rclib")
        var inputs = extraInputs
        for package in packages {
            let root = URL(fileURLWithPath: package.directory)
            inputs.append(root)
            let entries = try FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey]
            )
            for entry in entries {
                let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
                if values.isRegularFile == true {
                    inputs.append(entry)
                } else if values.isDirectory == true,
                          ["licenses", "licences", "legal"].contains(entry.lastPathComponent.lowercased()) {
                    inputs.append(entry)
                    inputs += try FileManager.default.contentsOfDirectory(at: entry, includingPropertiesForKeys: nil)
                }
            }
        }
        return [.buildCommand(
            displayName: "Collect Swift package licenses",
            executable: tool,
            arguments: [String(decoding: data, as: UTF8.self), output.path],
            inputFiles: Array(Set(inputs)).sorted { $0.path < $1.path },
            outputFiles: [output]
        )]
    }
    
    private struct PackageInput: Codable {
        internal let id: String
        internal let name: String
        internal let directory: String
    }
}

#if canImport(XcodeProjectPlugin)
extension RegulatoryCoreLicensePlugin: XcodeBuildToolPlugin {
    internal func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        var roots = Set<URL>()
        var visited = Set<String>()
        func visit(_ target: Target) {
            guard visited.insert(target.id).inserted else { return }
            if let root = packageRoot(containing: target.directoryURL) { roots.insert(root) }
            for dependency in target.dependencies {
                switch dependency {
                case .target(let target): visit(target)
                case .product(let product): product.targets.forEach(visit)
                @unknown default: break
                }
            }
        }
        for target in context.xcodeProject.targets {
            for dependency in target.dependencies {
                if case .product(let product) = dependency { product.targets.forEach(visit) }
            }
        }
        var packages: [String: PackageInput] = [:]
        var knownDirectories = Set<URL>()
        var extraInputs: [URL] = []
        // Xcode's workspace state also includes packages containing only binary targets.
        if let state = workspaceState(near: [context.pluginWorkDirectoryURL] + roots.sorted(by: { $0.path < $1.path })) {
            extraInputs.append(state)
            let workspace = try JSONDecoder().decode(WorkspaceState.self, from: Data(contentsOf: state))
            for dependency in workspace.object.dependencies {
                let reference = dependency.packageRef
                let directory: URL
                if reference.kind == "fileSystem" {
                    directory = URL(fileURLWithPath: reference.location)
                } else {
                    let folder = reference.kind == "registry" ? "registry/downloads" : "checkouts"
                    directory = state.deletingLastPathComponent()
                        .appendingPathComponent(folder).appendingPathComponent(dependency.subpath)
                }
                knownDirectories.insert(directory.resolvingSymlinksInPath())
                guard !isExcludedRepository(reference.location) else { continue }
                packages[reference.identity] = .init(
                    id: reference.identity,
                    name: packageName(in: directory, fallback: reference.name ?? reference.identity),
                    directory: directory.path
                )
            }
        }
        for root in roots where !knownDirectories.contains(root.resolvingSymlinksInPath()) {
            guard !isExcludedCheckout(root) else { continue }
            let id = root.lastPathComponent.lowercased()
            packages[id] = .init(id: id, name: packageName(in: root, fallback: root.lastPathComponent), directory: root.path)
        }
        return try commands(
            packages: Array(packages.values),
            tool: context.tool(named: "RegulatoryCoreLicenseTool").url,
            workDirectory: context.pluginWorkDirectoryURL,
            extraInputs: extraInputs
        )
    }
    
    private func isExcludedCheckout(_ directory: URL) -> Bool {
        guard let config = try? String(
            contentsOf: directory.appendingPathComponent(".git/config"),
            encoding: .utf8
        ) else {
            return false
        }
        var isOrigin = false
        for line in config.components(separatedBy: .newlines) {
            let line = line.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                isOrigin = line == "[remote \"origin\"]"
            } else if isOrigin {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == "url" {
                    return isExcludedRepository(String(parts[1]))
                }
            }
        }
        return false
    }
    
    private func packageRoot(containing directory: URL) -> URL? {
        var directory = directory
        while directory.path != "/" {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("Package.swift").path) { return directory }
            directory.deleteLastPathComponent()
        }
        return nil
    }
    
    private func workspaceState(near directories: [URL]) -> URL? {
        for directory in directories {
            var current = directory
            while current.path != "/" {
                for path in ["workspace-state.json", "SourcePackages/workspace-state.json", ".build/workspace-state.json"] {
                    let candidate = current.appendingPathComponent(path)
                    if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
                }
                current.deleteLastPathComponent()
            }
        }
        return nil
    }
    
    private func packageName(in directory: URL, fallback: String) -> String {
        guard let manifest = try? String(contentsOf: directory.appendingPathComponent("Package.swift"), encoding: .utf8),
              let range = manifest.range(of: #"Package\s*\(\s*name\s*:\s*"([^"]+)""#, options: .regularExpression) else {
            return fallback
        }
        return String(manifest[range].split(separator: "\"")[1])
    }
    
    private struct WorkspaceState: Decodable {
        internal let object: StateObject
        
        internal struct StateObject: Decodable {
            internal let dependencies: [Dependency]
        }
        
        internal struct Dependency: Decodable {
            internal let packageRef: Reference
            internal let subpath: String
        }
        
        internal struct Reference: Decodable {
            internal let identity: String
            internal let name: String?
            internal let kind: String
            internal let location: String
        }
    }
}
#endif
