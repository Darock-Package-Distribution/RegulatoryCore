# RegulatoryCore

RegulatoryCore collects Swift package licenses during builds and exposes them through `LRCPackageLicense`.

Requires Swift 6.1 or later.

## Xcode

Add this package to your project. In your app target's **Build Phases → Run Build Tool Plug-ins**, add **RegulatoryCoreLicensePlugin**. The plugin collects the project's direct and transitive SwiftPM dependencies, serializes their licenses as JSON, and compresses them with AppleArchive using LZFSE. Xcode copies the generated `LRCPLDefault.rclib` into the app's main bundle.

```swift
import RegulatoryCore

let licenses = LRCPackageLicense.defaultLicenses()
```

License names are inferred from SPDX identifiers and common license text. Each dependency produces one entry; multiple license files are combined. Unknown license names remain `nil`. Dependencies without license text produce a build warning and an entry with empty content. Missing or invalid archives decode to an empty array.

## SwiftPM targets

Apply the plugin to the consuming target:

```swift
.package(name: "RegulatoryCore", path: "../RegulatoryCore/Package")

// Target declaration:
.executableTarget(
    name: "App",
    dependencies: [.product(name: "RegulatoryCore", package: "RegulatoryCore")],
    plugins: [.plugin(name: "RegulatoryCoreLicensePlugin", package: "RegulatoryCore")]
)
```

SwiftPM places the generated archive in that target's resource bundle (`Bundle.module`). Use the Xcode app target integration above for `Bundle.main` and `defaultLicenses()`.
