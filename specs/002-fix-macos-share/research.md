# Research: Fix macOS Share Handler

**Feature**: 002-fix-macos-share
**Date**: 2026-04-22

## Finding 1: Protocol Mismatch — Root Cause of macOS Failure

**Decision**: Replace `NSApplicationDelegate` methods with `FlutterAppLifecycleDelegate` protocol methods in the macOS plugin

**Rationale**: The macOS plugin (`SwiftShareHandlerMacosPlatform`) implements `application(_:open:)`, `applicationDidFinishLaunching(_:)`, and other `NSApplicationDelegate` methods. However, Flutter's macOS engine does NOT call these methods on plugins. Instead, it uses a custom `FlutterAppLifecycleDelegate` protocol with different method signatures:

| Current (dead code) | Required (Flutter protocol) |
|---|---|
| `application(_:open:)` | `handleOpenURLs(_:) -> Bool` |
| `applicationDidFinishLaunching(_:)` | `handleDidFinishLaunching(_:) -> Bool` |
| `applicationShouldHandleReopen(_:hasVisibleWindows:)` | Not available in protocol |

The Flutter engine's `FlutterAppDelegate` receives `application:openURLs:` from macOS, then iterates over registered lifecycle delegates calling `handleOpenURLs:`. The current plugin's `application(_:open:)` is never invoked.

This is why the app opens but nothing happens — the URL is received by macOS and passed to `FlutterAppDelegate`, but the plugin never gets notified.

**Alternatives considered**:
- Overriding `AppDelegate` to manually forward events (rejected: breaks plugin encapsulation)
- Using `NSAppleEventManager` for URL handling (rejected: not needed when proper protocol is used)

## Finding 2: ShareExtension Entitlements Not Wired in Build Settings

**Decision**: Ensure `CODE_SIGN_ENTITLEMENTS` is set for the macOS ShareExtension target

**Rationale**: The `ShareExtension.entitlements` file exists in the macOS example project but is NOT referenced in any `CODE_SIGN_ENTITLEMENTS` build setting for the ShareExtension target in `project.pbxproj`. Without this, Xcode won't embed the app group entitlements into the signed extension binary, so the extension can't access shared UserDefaults.

**Alternatives considered**:
- Using Xcode's automatic entitlement handling (rejected: unreliable for extensions)

## Finding 3: Example App Issues

**Decision**: Delete and recreate the example app from scratch

**Rationale**: Multiple issues identified:
1. iOS example: `SceneDelegate.swift` referenced in pbxproj but missing from disk (build failure)
2. iOS example: `CUSTOM_GROUP_ID` mismatch between build settings and entitlements
3. iOS example: `ARCHS = 'x86_64'` restriction on ShareExtension prevents arm64 builds
4. Stale widget test that doesn't match actual app
5. User explicitly requested to wipe and recreate

**Alternatives considered**:
- Fix issues individually (rejected: user explicitly asked to recreate)

## Finding 4: App Group Key Inconsistency on macOS

**Decision**: Use a single consistent app group ID and the correct entitlement key

**Rationale**: The macOS entitlements use both `com.apple.security.app-groups` (iOS-style) and `com.apple.security.application-groups` (macOS-style) with different values. The plugin code uses `UserDefaults(suiteName: appGroupId)` where `appGroupId` defaults to `group.\(Bundle.main.bundleIdentifier!)`. The entitlement keys and group IDs must be consistent.

For macOS, the correct key is `com.apple.security.application-groups` for sandboxed apps. However, `UserDefaults(suiteName:)` works with the suite name regardless of which entitlement key declares it, as long as the app group is properly provisioned.

**Alternatives considered**:
- Use only one key (chosen: use both for maximum compatibility)

## Finding 5: FlutterAppLifecycleDelegate Available Methods

**Decision**: Use `handleOpenURLs:` for URL reception and `handleDidFinishLaunching:` for cold start

**Rationale**: From the Flutter engine header `FlutterAppLifecycleDelegate.h`, the available methods relevant to share handling are:
- `handleOpenURLs:(NSArray<NSURL*>*)urls` → returns BOOL
- `handleDidFinishLaunching:(NSNotification*)notification` → returns BOOL
- `handleWillFinishLaunching:(NSNotification*)notification` → returns BOOL

The plugin must implement these exact method signatures. The existing `applicationShouldHandleReopen` has no equivalent and should be removed or handled differently (it's not needed for share handling).

**Alternatives considered**:
- Subclass FlutterAppDelegate directly in the plugin (rejected: not possible, plugins register as delegates)
