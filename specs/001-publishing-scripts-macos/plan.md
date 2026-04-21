# Implementation Plan: Publishing Scripts and macOS Platform Support

**Branch**: `001-publishing-scripts-macos` | **Date**: 2026-04-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-publishing-scripts-macos/spec.md`

## Summary

Implement publishing scripts (5 shell scripts mirroring zikzak_inappwebview) and a full macOS platform implementation for the federated zikzak_share_handler plugin. The macOS implementation follows the same two-target architecture as iOS (main app plugin + share extension with shared models pod), adapted for macOS (AppKit instead of UIKit, NSApplicationDelegate instead of UIApplicationDelegate/SceneDelegate). URL sharing is implemented first as the testable foundation, with the example app printing received URLs.

## Technical Context

**Language/Version**: Dart (SDK >=2.14.0 <4.0.0), Swift 5.0, Bash
**Primary Dependencies**: Flutter (>=2.0.0), FlutterMacOS, CocoaPods, AppKit, Foundation
**Storage**: App Group container (UserDefaults + FileManager for file sharing between extension and main app)
**Testing**: flutter test, macOS build verification, manual URL sharing from Safari
**Target Platform**: macOS 10.11+ (podspec), macOS desktop
**Project Type**: Federated Flutter plugin (8 packages)
**Performance Goals**: Share reception within 1 second of user action
**Constraints**: Share Extension must not import Flutter (requires separate models pod)
**Scale/Scope**: 8 federated packages, 5 publishing scripts, 1 new full platform implementation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution file is a template (not configured). No gates to enforce. Proceeding.

**Post-Phase 1 re-check**: No violations. Design follows established iOS patterns.

## Project Structure

### Documentation (this feature)

```text
specs/001-publishing-scripts-macos/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── macOS-platform-contracts.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
scripts/                                   # NEW - Publishing scripts
├── prepare_for_publish.sh
├── publish.sh
├── restore_dev_setup.sh
├── revert_publish_changes.sh
└── push_to_master.sh

zikzak_share_handler/                      # Main app-facing package
├── lib/
│   ├── zikzak_share_handler.dart
│   └── src/zikzak_share_handler.dart
├── pubspec.yaml                           # MODIFY: enable macOS + other platforms
└── example/                               # MODIFY: add macOS support, share extension target
    ├── lib/
    ├── macos/                             # MODIFY: existing macOS runner
    ├── ios/
    └── pubspec.yaml

zikzak_share_handler_platform_interface/   # MODIFY: SharedAttachment.decode macOS support
├── lib/
│   └── src/
│       ├── data/messages.dart             # MODIFY: Platform.isMacOS check
│       ├── method_channel/method_channel_zikzak_share_handler.dart
│       └── platform_interface/platform_zikzak_share_handler.dart
└── pubspec.yaml

zikzak_share_handler_macos/                # REWRITE: Full macOS implementation
├── lib/
│   ├── zikzak_share_handler_macos.dart
│   └── src/
│       └── zikzak_share_handler_macos.dart    # REWRITE: full platform implementation
├── macos/
│   ├── zikzak_share_handler_macos.podspec     # RENAME + UPDATE
│   ├── Classes/
│   │   ├── ShareHandlerMacosPlugin.h          # NEW: Obj-C bridge
│   │   ├── ShareHandlerMacosPlugin.m          # NEW: Obj-C bridge
│   │   ├── SwiftShareHandlerMacosPlatform.swift  # REWRITE: full native implementation
│   │   └── ShareHandlerApi.swift              # NEW: Pigeon-generated API
│   └── Models/                                # NEW: shared models for share extension
│       ├── zikzak_share_handler_macos_models.podspec
│       └── Classes/
│           ├── SharedModels.swift             # NEW: SharedMedia/SharedAttachment
│           └── ShareHandlerMacosViewController.swift  # NEW: Share Extension VC
├── test/
└── pubspec.yaml                               # FIX: macos platform, implements, dartPluginClass
```

**Structure Decision**: Federated Flutter plugin monorepo with 8 packages. New files added to existing `zikzak_share_handler_macos/` package. New `scripts/` directory at root for publishing workflow. Example app gets macOS share extension target.

## Implementation Order

Based on user directive: **macOS first, URL sharing first, as modernization playground**.

### Phase A: macOS Platform Foundation (must be first)
1. Fix macOS pubspec.yaml (platform, implements, dartPluginClass)
2. Fix macOS podspec (name, structure)
3. Rewrite Dart platform implementation (registerWith, full API)
4. Rewrite native Swift plugin (Pigeon API, EventChannel, NSApplicationDelegate)
5. Create shared models pod (SharedModels.swift, ShareHandlerMacosViewController.swift)
6. Enable macOS in main package pubspec.yaml
7. Update SharedAttachment.decode for macOS

### Phase B: Example App macOS Setup
8. Add macOS Share Extension target to example app
9. Configure App Groups, URL schemes, entitlements
10. Add example code that prints shared URLs
11. Build and test URL sharing from Safari

### Phase C: Publishing Scripts
12. Create `scripts/prepare_for_publish.sh` (ported from inappwebview)
13. Create `scripts/publish.sh`
14. Create `scripts/restore_dev_setup.sh`
15. Create `scripts/revert_publish_changes.sh`
16. Create `scripts/push_to_master.sh`

### Phase D: Enable Other Platforms
17. Uncomment web/windows/linux in main package pubspec.yaml
18. Verify other platform packages compile

## Complexity Tracking

> No constitution violations. Table left empty.
