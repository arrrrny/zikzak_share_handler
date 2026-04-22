# Implementation Plan: Fix macOS Share Handler

**Branch**: `002-fix-macos-share` | **Date**: 2026-04-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-fix-macos-share/spec.md`

## Summary

Fix the macOS share handler plugin so that shared links/text/files are received and delivered to the Flutter app. The root cause is a protocol mismatch: the macOS plugin implements `NSApplicationDelegate` methods but Flutter's macOS engine uses `FlutterAppLifecycleDelegate` protocol with different method signatures. Additionally, recreate the example app from scratch with proper macOS and iOS configuration.

## Technical Context

**Language/Version**: Swift 5.0, Dart 3.0+
**Primary Dependencies**: Flutter macOS SDK, FlutterMacOS framework, Pigeon (message channels)
**Storage**: Shared UserDefaults via App Groups (extension ↔ host app communication)
**Testing**: Flutter integration tests, manual testing via macOS share sheet
**Target Platform**: macOS 13+, iOS 15+
**Project Type**: Federated Flutter plugin with example app
**Performance Goals**: Shared content delivered to Flutter app within 3 seconds
**Constraints**: Must maintain backward compatibility with existing Dart API
**Scale/Scope**: Single plugin fix + example app recreation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is in template state (not customized). No violations to check. Proceeding.

## Project Structure

### Documentation (this feature)

```text
specs/002-fix-macos-share/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research findings
├── data-model.md        # Phase 1 data model
├── quickstart.md        # Phase 1 quickstart guide
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
zikzak_share_handler_macos/
├── macos/
│   ├── Classes/
│   │   ├── SwiftShareHandlerMacosPlatform.swift  # FIX: Replace delegate methods
│   │   ├── ShareHandlerMacosPlugin.m             # No changes needed
│   │   └── ShareHandlerApi.swift                 # No changes needed
│   └── Models/Classes/
│       ├── SharedModels.swift                    # No changes needed
│       └── ShareHandlerMacosViewController.swift # No changes needed
├── lib/
│   └── src/
│       └── zikzak_share_handler_macos.dart       # No changes needed
└── pubspec.yaml                                  # No changes needed

zikzak_share_handler/example/                     # DELETE AND RECREATE
├── lib/main.dart                                 # New example app
├── pubspec.yaml                                  # New pubspec
├── ios/                                          # New iOS configuration
│   ├── Runner/
│   │   ├── Info.plist                           # URL schemes, document types
│   │   ├── AppDelegate.swift                    # Standard FlutterAppDelegate
│   │   └── Runner.entitlements                  # App groups
│   ├── ShareExtension/
│   │   ├── ShareViewController.swift            # Subclass of base VC
│   │   ├── Info.plist                           # NSExtension config
│   │   └── ShareExtension.entitlements          # App groups
│   └── Podfile                                  # ShareExtension pod
├── macos/                                        # New macOS configuration
│   ├── Runner/
│   │   ├── Info.plist                           # URL schemes
│   │   ├── AppDelegate.swift                    # FlutterAppDelegate
│   │   ├── DebugProfile.entitlements            # App groups + sandbox
│   │   └── Release.entitlements                 # App groups + sandbox
│   ├── ShareExtension/
│   │   ├── ShareViewController.swift            # Subclass of base VC
│   │   ├── Info.plist                           # NSExtension config
│   │   └── ShareExtension.entitlements          # App groups
│   └── Podfile                                  # ShareExtension pod
└── test/
    └── widget_test.dart                         # Updated test
```

**Structure Decision**: Existing federated plugin structure is preserved. Only the macOS plugin Swift code needs modification, and the example app is fully recreated.

## Implementation Phases

### Phase 1: Fix macOS Plugin Core (SwiftShareHandlerMacosPlatform.swift)

**1.1 Replace NSApplicationDelegate methods with FlutterAppLifecycleDelegate methods**

Current dead code:
```swift
public func application(_ application: NSApplication, open urls: [URL]) { ... }
public func applicationDidFinishLaunching(_ notification: Notification) { ... }
public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { ... }
public func application(_ sender: NSApplication, openFile filename: String) -> Bool { ... }
public func application(_ sender: NSApplication, openFiles filenames: [String]) -> Bool { ... }
```

Replace with:
```swift
public func handleOpenURLs(_ urls: [URL]) -> Bool {
    for url in urls {
        if hasMatchingSchemePrefix(url: url) {
            _ = handleUrl(url: url, setInitialData: false)
        }
    }
    return true
}

public func handleDidFinishLaunching(_ notification: Notification) -> Bool {
    if let userDefaults = notification.userInfo?[NSApplication.launchUserNotificationUserInfoKey] as? [AnyHashable: Any] {
        for (_, value) in userDefaults {
            if let url = value as? URL {
                if hasMatchingSchemePrefix(url: url) {
                    _ = handleUrl(url: url, setInitialData: true)
                }
            }
        }
    }
    return true
}
```

**Key changes**:
- `application(_:open:)` → `handleOpenURLs(_:) -> Bool`
- `applicationDidFinishLaunching(_:)` → `handleDidFinishLaunching(_:) -> Bool`
- Remove `applicationShouldHandleReopen`, `application(_:openFile:)`, `application(_:openFiles:)` (dead code)

**1.2 Verify existing `handleUrl` and `hasMatchingSchemePrefix` logic**

The `handleUrl(url:setInitialData:)` private method is correct — it reads from UserDefaults, decodes SharedMedia, and pushes to eventSink. No changes needed there.

### Phase 2: Recreate Example App

**2.1 Delete existing example directory**

```bash
rm -rf zikzak_share_handler/example/
```

**2.2 Create new Flutter example project**

```bash
cd zikzak_share_handler
flutter create --platforms=ios,macos example/
```

**2.3 Configure iOS example**

Reference: existing iOS configuration from deleted app (captured in research.md)

1. **Runner/Info.plist**:
   - Add `CFBundleURLTypes` with `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` scheme
   - Add `CFBundleDocumentTypes` for share-compatible types
   - Add `NSUserActivityTypes` for `INSendMessageIntent`

2. **Runner/Runner.entitlements**:
   - Add `com.apple.security.application-groups` with app group ID

3. **ShareExtension/** (new target, manually created):
   - `ShareViewController.swift`: subclass of `ShareHandlerIosViewController`
   - `Info.plist`: NSExtension config with activation rules
   - `ShareExtension.entitlements`: matching app group ID

4. **Podfile**: Add ShareExtension nested target with `zikzak_share_handler_ios_models` pod

5. **Xcode project**: Add ShareExtension target with proper build settings, entitlements, and embedding

**2.4 Configure macOS example**

Reference: iOS example as template, adapted for macOS

1. **Runner/Info.plist**:
   - Add `CFBundleURLTypes` with `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` scheme

2. **Runner/DebugProfile.entitlements & Release.entitlements**:
   - Add `com.apple.security.application-groups` with app group ID
   - Keep `com.apple.security.app-sandbox`

3. **ShareExtension/** (new target):
   - `ShareViewController.swift`: subclass of `ShareHandlerMacosViewController`
   - `Info.plist`: NSExtension config with activation rules
   - `ShareExtension.entitlements`: matching app group ID

4. **Podfile**: Add ShareExtension nested target with `zikzak_share_handler_macos_models` pod

5. **Xcode project**:
   - Add ShareExtension target
   - **CRITICAL**: Set `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements` for all ShareExtension build configurations
   - Set `REGISTER_APP_GROUPS = YES` on both Runner and ShareExtension

**2.5 Write example app Dart code**

Simple example app:
- Calls `ShareHandler.instance.getInitialSharedMedia()` on init
- Listens to `sharedMediaStream` for real-time shares
- Displays received content (text/URLs) and file attachments

**2.6 Update widget test**

Replace stale test with one matching the actual app.

### Phase 3: Verification

**3.1 Build and test on macOS**
- Build example app for macOS
- Verify no compilation errors
- Test share flow from Safari

**3.2 Build and test on iOS**
- Build example app for iOS
- Verify no compilation errors
- Verify existing iOS flow still works

**3.3 Run existing plugin tests**
- Run `flutter test` in each package

## Complexity Tracking

No constitution violations. No complexity justification needed.
