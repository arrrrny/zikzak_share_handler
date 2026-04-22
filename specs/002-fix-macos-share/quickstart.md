# Quickstart: Fix macOS Share Handler

**Feature**: 002-fix-macos-share
**Date**: 2026-04-22

## Prerequisites

- Flutter SDK 3.0+
- Xcode 15+
- macOS 13+ (for testing)
- CocoaPods

## Key Changes

### 1. macOS Plugin Fix

The only plugin code change is in `SwiftShareHandlerMacosPlatform.swift`. Replace `NSApplicationDelegate` methods with `FlutterAppLifecycleDelegate` protocol methods:

- `application(_:open:)` → `handleOpenURLs(_:) -> Bool`
- `applicationDidFinishLaunching(_:)` → `handleDidFinishLaunching(_:) -> Bool`
- Remove dead code: `applicationShouldHandleReopen`, `application(_:openFile:)`, `application(_:openFiles:)`

### 2. Example App Recreation

The example app is recreated from scratch with proper macOS and iOS share extension targets.

## Testing the Fix

### macOS

1. Build and run the example app on macOS
2. Open Safari, navigate to any webpage
3. Click the Share button → select the example app
4. Verify the shared URL appears in the app UI
5. Test with the app already running (warm resume)
6. Test with the app not running (cold start)

### iOS

1. Build and run the example app on iOS simulator/device
2. Share a URL from Safari to the example app
3. Verify existing iOS functionality is preserved

## Configuration Checklist for New Apps

When integrating this plugin into a new Flutter app:

### macOS Setup

1. Add a Share Extension target in Xcode
2. Set `ShareViewController` to subclass `ShareHandlerMacosViewController`
3. Register URL scheme `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` in Runner's Info.plist
4. Add app group to both Runner and ShareExtension entitlements
5. Ensure `CODE_SIGN_ENTITLEMENTS` is set for ShareExtension target
6. Add `zikzak_share_handler_macos_models` pod to ShareExtension in Podfile

### iOS Setup

1. Add a Share Extension target in Xcode
2. Set `ShareViewController` to subclass `ShareHandlerIosViewController`
3. Register URL scheme `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` in Runner's Info.plist
4. Add document types for share-compatible content types
5. Add app group to both Runner and ShareExtension entitlements
6. Add `zikzak_share_handler_ios_models` pod to ShareExtension in Podfile
