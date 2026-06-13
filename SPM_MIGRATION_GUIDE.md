# SPM Migration & Share Extension Fix Guide

## Overview

This guide covers everything we learned migrating `zikzak_share_handler_ios` and `zikzak_share_handler_macos` from CocoaPods-only to Swift Package Manager (SPM), fixing the stuck gray overlay on share extensions, and preparing for publishing.

---

## 1. SPM Migration for Flutter Plugin Packages

### Directory Structure

Flutter expects `Package.swift` at `ios/<package_name>/Package.swift` (or `macos/<package_name>/`).

```
ios/
  <package_name>.podspec
  <package_name>/
    Package.swift
    Sources/
      <package_name>/          ← main target
        *.swift
      <package_name>_models/   ← models target (if needed)
        *.swift
```

### Package.swift Template

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "zikzak_share_handler_ios",
    platforms: [
        .iOS("15.6") // match your minimum deployment target
    ],
    products: [
        .library(
            name: "zikzak-share-handler-ios", // hyphens for SPM, NOT underscores
            targets: ["zikzak_share_handler_ios"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "zikzak_share_handler_ios_models",
            dependencies: [],
            path: "Sources/zikzak_share_handler_ios_models"
        ),
        .target(
            name: "zikzak_share_handler_ios",
            dependencies: [
                "zikzak_share_handler_ios_models"
            ],
            path: "Sources/zikzak_share_handler_ios"
        ),
    ]
)
```

> **Library name rule:** Replace `_` with `-` in the product name (e.g., `zikzak_share_handler_ios` → `zikzak-share-handler-ios`).

### Remove ObjC Plugin Shim

Delete `ios/Classes/<Plugin>.h` and `ios/Classes/<Plugin>.m`. Rename the Swift class from `Swift<Plugin>Platform` to match the `pluginClass` in `pubspec.yaml`:

```swift
// Before
public class SwiftShareHandlerIosPlatform: NSObject, FlutterPlugin { ... }

// After
public class ShareHandlerIosPlatform: NSObject, FlutterPlugin { ... }
```

No `@objc` annotation needed — Flutter's SPM integration calls the Swift class directly.

### Fix Cross-Module Access

When moving from CocoaPods (single module) to SPM (separate modules), methods overridden by subclasses in other modules must be `open`, not `public`:

```swift
open override func viewDidLoad() {
    super.viewDidLoad()
    // ...
}

open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
}
```

### Add Missing `import Foundation`

SPM targets are strict about imports. Add `import Foundation` to any file using `Data`, `JSONSerialization`, `JSONEncoder`, etc.

### Update Podspecs

Point podspec source paths to the new SPM layout:

```ruby
s.source_files = 'zikzak_share_handler_ios/Sources/zikzak_share_handler_ios/**/*.swift'
s.dependency 'Flutter'
s.dependency 'zikzak_share_handler_ios_models'
```

Separate models podspec (for share extensions that need it without Flutter):

```ruby
# ios/zikzak_share_handler_ios_models.podspec
Pod::Spec.new do |s|
  s.name = 'zikzak_share_handler_ios_models'
  s.version = '0.0.34'
  s.source_files = 'zikzak_share_handler_ios/Sources/zikzak_share_handler_ios_models/**/*.swift'
  s.platform = :ios, '15.6'
  s.swift_version = '5.0'
end
```

### Gitignore

Add to `.gitignore`:
```
.build/
.swiftpm/
```

### macOS Differences

- Use `FlutterMacOS` instead of `Flutter`
- Import `FlutterMacOS` instead of `Flutter`
- Use `NSWorkspace.shared.open(url, configuration:)` instead of `UIApplication`
- Minimum deployment target: `10.13` (Xcode requirement)
- macOS `Package.swift`: `.macOS("10.15")`

---

## 2. Gray Overlay Fix (Critical!)

### Problem

When a share extension opens the host app via URL scheme and calls `completeRequest` immediately after, the source app's dimming overlay gets stuck because the app switch interrupts the dismissal animation.

### Root Cause

```
redirectToHostApp()        // opens URL → app switch starts
completeRequest()          // called during app switch → overlay stuck
```

### Fix

Call `completeRequest` from the **openURL completion handler**, not synchronously after it.

**iOS (`UIApplication`):**

```swift
private func openHostAppUrl() {
    guard let url = URL(string: "...") else { return }

    var responder = self as UIResponder?
    while responder != nil {
        if let application = responder as? UIApplication {
            application.open(url, options: [:]) { [weak self] _ in
                // completeRequest AFTER the app switch has completed
                self?.extensionContext?.completeRequest(
                    returningItems: [], completionHandler: nil)
            }
            return
        }
        responder = responder?.next
    }

    // Fallback: no UIApplication found
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
}
```

**macOS (`NSWorkspace`):**

```swift
NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, _ in
    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
}
```

> **Note:** `NSWorkspace.shared.open` completion handler receives **2 arguments** (`NSRunningApplication?`, `Error?`), not 1 like iOS.

### Why This Works

1. Save data to UserDefaults
2. Open host app URL → system switches to host app
3. **After** the switch completes, call `completeRequest`
4. Source app receives the dismiss signal when it's safely in the background
5. When user returns to source app, the overlay is gone

Do **NOT** use fixed delays (`Task.sleep`). The completion handler is the correct mechanism.

---

## 3. CocoaPods → SPM Cleanup for Example App

After all plugins support SPM, clean up your example app:

### Remove CocoaPods

```bash
cd example/ios
pod deintegrate
rm Podfile
```

```bash
cd example/macos
pod deintegrate
rm Podfile
```

### Remove Pods xcconfig Includes

Edit each xcconfig that still includes Pods paths:

**`ios/Flutter/Debug.xcconfig`** → remove `#include? "Pods/..."` lines
**`ios/Flutter/Release.xcconfig`** → remove `#include? "Pods/..."` lines
**`ios/ShareExtension/Debug.xcconfig`** → remove `#include? "Pods/..."` lines
**`ios/ShareExtension/Release.xcconfig`** → remove `#include? "Pods/..."` lines

Same for macOS equivalents.

### Update Project Deployment Target

Set project-level `IPHONEOS_DEPLOYMENT_TARGET` to match your minimum (e.g., 15.6) so SPM doesn't complain about platform version mismatches.

---

## 4. Share Extension with SPM

SPM has a limitation: the Flutter-generated plugin package (`FlutterGeneratedPluginSwiftPackage`) depends on your plugin package, and you **cannot add a second reference** to the same package in the Xcode project without causing a duplicate identity error.

### For Plugin Repos (Example Apps)

Copy the models source files directly into the ShareExtension target:

1. Copy `ShareHandlerIosViewController.swift` and `SharedModels.swift` into `ios/ShareExtension/`
2. Add them to the ShareExtension's **Compile Sources** in Xcode
3. Remove `import zikzak_share_handler_ios_models` from your `ShareViewController.swift`
4. The types are now in the same module, no import needed

### For Consumer Apps (Your Real App)

Your app's ShareExtension should follow the same pattern. Since you control both the plugin and the app:

1. Your main app gets the plugin via SPM (Runner target)
2. Your ShareExtension copies/compiles the view controller source directly
3. The copy-approach is safe because the extension is a separate process

---

## 5. Publishing Checklist

### Pre-publish Script (`prepare_for_publish.sh`)

Your script should:

1. **Version bump**: Update `pubspec.yaml` for ALL packages (including linux, web, windows)
2. **Podspec version**: Update `s.version` in all `.podspec` files
3. **Convert path deps**: Change `path: ../zikzak_share_handler_...` → `^0.0.34` in ALL `pubspec.yaml` files (root AND platform packages)
4. **CHANGELOG**: Generate entries for all packages (or use consistent text)
5. **Verify**: Check no `path:` dependencies remain
6. **Publish order**: platform_interface → android → ios → macos → linux → web → windows → root

> **Important:** The root `zikzak_share_handler/pubspec.yaml` must have ALL platform deps as hosted (`^0.0.34`), not `path:`.

### Post-publish Restore (`restore_dev_setup.sh`)

Run after publishing to switch back to path deps for local development:

```bash
./scripts/restore_dev_setup.sh
```

This converts all `^0.0.34` hosted references back to `path: ../zikzak_share_handler_...`.

---

## 6. TL;DR — Quick Recipe

1. Create `ios/<package_name>/Package.swift` with `Sources/<target>/` structure
2. Delete `Classes/<Plugin>.h/.m` (ObjC shim)
3. Rename `Swift<Plugin>Platform` → `<Plugin>Platform` (match pubspec)
4. Change `public override viewDidLoad` → `open override viewDidLoad`
5. Add `import Foundation` where needed
6. Fix `completeRequest` → call from openURL completion handler
7. Update podspecs to new `Sources/` paths
8. Add `.build/` and `.swiftpm/` to gitignore
9. For share extensions in example apps: copy source files + remove import
10. Deintegrate CocoaPods from example apps: `pod deintegrate`, clean xcconfigs
