# Research: Publishing Scripts

**Feature**: 001-publishing-scripts-macos
**Date**: 2026-04-21

## R1: Package List Scoping

**Decision**: Only include 5 active packages (platform_interface, android, ios, macos, main). Exclude linux, web, windows.

**Rationale**: User explicitly stated "only covers ios, macos, android — these 3 is enough." The linux/web/windows packages exist in the repo but are commented out in the main package pubspec.yaml and should not be part of the publish workflow.

**Alternatives considered**: Including all 8 packages (rejected — would publish inactive stubs); Making package list configurable via env var (unnecessary complexity — just edit the script when new platforms are activated).

## R2: Podspec Version Updates

**Decision**: Update all 4 podspecs (2 iOS + 2 macOS) during `prepare_for_publish.sh`.

**Rationale**: Reference project updates podspecs for iOS and macOS. This project has the same pattern — each platform has a main podspec and a models sub-podspec. The models podspecs also contain version lines that must be updated.

**Alternatives considered**: Only updating main podspecs (rejected — models podspecs have independent versions and would drift); Using a Dart script for podspec manipulation (rejected — sed is sufficient and matches reference).

## R3: Podspec Version Line Patterns

**Decision**: Use sed to replace `s.version = 'X.Y.Z'` pattern, matching the reference project approach.

**Rationale**: All 4 podspecs follow the pattern `s.version = 'X.Y.Z'` (with varying whitespace). The reference project uses `sed -i '' "s/s\.version.*=.*/s.version          = '$VERSION'/"` which works correctly.

**Alternatives considered**: Ruby/CocoaPods API (overkill); awk-based parsing (unnecessary complexity).

## R4: Dependency Conversion Strategy

**Decision**: Adapt the reference project's `convert_path_to_versioned()` function, scoped to `zikzak_share_handler_*` package names.

**Rationale**: The reference implementation handles both single-line (`package: ^X.Y.Z`) and multi-line path dependencies (`package:\n  path: ../package`) comprehensively with sed and awk. Same patterns apply here — the main package and platform packages all use path dependencies in development mode.

**Alternatives considered**: Simple sed-only approach (rejected — doesn't handle multi-line path deps); yaml-aware tooling like yq (adds dependency, reference project works fine without it).

## R5: Restore Dev Setup — Path Dependency Format

**Decision**: Restore dependencies as multi-line format (`package:\n    path: ../package`), matching the existing pubspec.yaml style.

**Rationale**: Current pubspec.yaml files use multi-line format for path dependencies. The restore script should produce output matching the existing style to minimize diff noise.

**Alternatives considered**: Single-line format (inconsistent with existing style).

## R6: Main Branch Name

**Decision**: Use `master` as the main branch name, matching the reference project and spec assumption.

**Rationale**: Spec states "The main branch is called `master` (consistent with inappwebview setup)." The `push_to_master.sh` and `revert_publish_changes.sh` scripts reference `master`.

**Alternatives considered**: Detecting default branch dynamically (unnecessary — project convention is `master`).

## R7: Commented-Out Dependencies

**Decision**: The `prepare_for_publish.sh` script should NOT touch commented-out dependency lines. The `restore_dev_setup.sh` script should leave commented lines as-is.

**Rationale**: Linux/web/windows dependencies are commented out in the main pubspec.yaml. The prepare script only processes active (uncommented) path dependencies. This naturally excludes inactive platforms from the conversion.

**Alternatives considered**: Uncommenting all platforms during publish (rejected — user wants only 3 active platforms).
