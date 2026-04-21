# Research: Publishing Scripts and macOS Platform Support

**Date**: 2026-04-15
**Branch**: `001-publishing-scripts-macos`

## Decision 1: macOS Share Extension Architecture

**Decision**: Use the same two-target architecture as iOS (Main App + Share Extension) with shared models pod, adapted for macOS.

**Rationale**:
- macOS supports the same Share Extension mechanism (`com.apple.share-services` NSExtension point)
- `NSExtensionContext.inputItems`, `UserDefaults(suiteName:)`, App Groups, and custom URL schemes all work identically on macOS
- The iOS implementation has a proven, tested pattern that handles all edge cases (cold start, warm resume, stream vs initial media)
- The two-podspec design (main plugin + shared models) is essential because the Share Extension target cannot import Flutter

**Alternatives considered**:
- **Apple Events / NSAppleEventManager**: Could receive URLs without a share extension but doesn't handle the share sheet UI. Would lose the visual share experience.
- **Drop target / file URL handling**: Only works for drag-and-drop, not the system share sheet.
- **Single-target without share extension**: Would only work for URL schemes, not for sharing text/files from other apps.

## Decision 2: macOS-Specific Adaptations from iOS

**Decision**: Key differences from iOS implementation:

| iOS Pattern | macOS Adaptation |
|---|---|
| `UIViewController` → Share Extension VC | `NSViewController` → Share Extension VC |
| `UIApplication.shared.open(url)` | `NSWorkspace.shared.open(url)` |
| `UIApplicationDelegate` + `UISceneDelegate` | `NSApplicationDelegate` only (no scene delegate on macOS) |
| `registrar.addSceneDelegate()` | Not needed on macOS |
| `FlutterSceneDelegate` | Not applicable; use `FlutterAppDelegate` on macOS |
| `PHAsset` paths (`/var/mobile/Media`) | Local file paths, no `/var/mobile` prefix |
| `MainInterface.storyboard` (iOS) | `MainInterface.storyboard` (macOS format) |
| `INSendMessageIntent` | Available on macOS but lower priority; skip for initial URL sharing |

**Rationale**: macOS and iOS share Foundation, Cocoa patterns, and the extension mechanism. The main differences are UIKit→AppKit (NS prefix) and no scene delegate lifecycle.

## Decision 3: Implementation Phasing - URL Sharing First

**Decision**: Implement URL sharing first, then extend to other media types.

**Rationale**:
- User explicitly requested this phasing: "focus on sharing urls first then we can extend to other media types"
- URL sharing is the simplest flow to validate the entire pipeline (Share Extension → App Group → Custom URL Scheme → Flutter)
- Faster to test on macOS (can share URLs from Safari directly)
- Once URL sharing works, adding text/file/image support is incremental (same architecture, different UTI handling)

**Scope for initial URL sharing**:
- Share Extension accepts URLs (UTI: `public.url`, `public.file-url`)
- Share Extension stores URL in App Group UserDefaults
- Share Extension opens main app via custom URL scheme
- Main app plugin receives URL, decodes SharedMedia, fires stream/returns initial media
- Example app prints received URL

## Decision 4: macOS as Modernization Playground

**Decision**: Use macOS implementation to establish modern patterns (SDK versions, lifecycle handling) that can later be backported to iOS.

**Rationale**:
- User stated: "macos would be a great playground to work with new lifecycles and can provide base path for modernizing the ios"
- macOS only uses `NSApplicationDelegate` (simpler than iOS's dual AppDelegate+SceneDelegate)
- Can establish clean SDK constraints and patterns without iOS backward compatibility concerns
- Proven on macOS first, then port to iOS with confidence

## Decision 5: Publishing Scripts - Direct Port from inappwebview

**Decision**: Port all 5 scripts from `zikzak_inappwebview/scripts/` with package name substitutions.

**Rationale**:
- The inappwebview scripts are battle-tested with the same federated plugin structure
- Same conventions: `publish-X.Y.Z` branches, version sync, path↔versioned dependency conversion
- Package order is equivalent: platform_interface → platform implementations → main package
- The only differences are package names (8 packages vs 9 in inappwebview)

**Package order for publishing**:
1. `zikzak_share_handler_platform_interface`
2. `zikzak_share_handler_android`
3. `zikzak_share_handler_ios`
4. `zikzak_share_handler_macos`
5. `zikzak_share_handler_web`
6. `zikzak_share_handler_windows`
7. `zikzak_share_handler_linux`
8. `zikzak_share_handler`

## Decision 6: Podspec and Native Plugin Registration

**Decision**: Use CocoaPods (same as iOS) with `FlutterMacOS` dependency and proper macOS platform declaration.

**Rationale**:
- Flutter macOS plugins use CocoaPods natively
- The inappwebview macOS plugin follows this exact pattern
- Podspec name must match pubspec package name for federated plugin resolution
- Current podspec incorrectly uses `FlutterMacOS` but has wrong platform (`ios`) in pubspec

## Decision 7: SharedAttachment.decode Platform Handling

**Decision**: Extend `Platform.isIOS` check to `Platform.isIOS || Platform.isMacOS` for URI decoding.

**Rationale**:
- macOS also URL-encodes paths in share contexts
- Both platforms use the same Foundation framework
- Minimal change, no risk to existing iOS/Android behavior
