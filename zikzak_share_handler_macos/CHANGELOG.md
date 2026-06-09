## 0.0.34 - 2026-06-09

* Prepare for publishing version 0.0.34
## 0.0.34 - 2026-06-09

- **SPM support**: Added Swift Package Manager support with `Package.swift`
- **Pure Swift**: Removed Objective-C plugin shim (`ShareHandlerMacosPlugin.h/.m`)
- **Gray overlay fix**: `completeRequest` called from `NSWorkspace.shared.open` completion handler so source app dismisses cleanly after host app launch
- **Cross-module fix**: `viewDidLoad` changed to `open override` for subclassing outside the module
- **Restructured**: Source files moved to `Sources/zikzak_share_handler_macos/` and `Sources/zikzak_share_handler_macos_models/`
- **Podspecs**: Updated to point to new SPM-compatible paths, raised min macOS to 10.13
- **Renamed**: `SwiftShareHandlerMacosPlatform` → `ShareHandlerMacosPlatform` (matches pubspec `pluginClass`)
- **Gitignore**: Added `.build/` and `.swiftpm/`

## 0.0.31 - 2026-04-21

- fix: UIApplication.openURL is deprecated

# 0.0.1

Initial release of this plugin.
