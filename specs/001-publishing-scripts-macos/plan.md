# Implementation Plan: Publishing Scripts

**Branch**: `001-publishing-scripts-macos` | **Date**: 2026-04-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-publishing-scripts-macos/spec.md`

## Summary

Create 5 publishing shell scripts (`prepare_for_publish.sh`, `publish.sh`, `restore_dev_setup.sh`, `revert_publish_changes.sh`, `push_to_master.sh`) adapted from the `zikzak_inappwebview` reference project, scoped to the 5 active packages (platform_interface, android, ios, macos, main). Scripts handle version synchronization, path-to-versioned dependency conversion, podspec updates, changelog generation, ordered pub.dev publishing with dependency verification, and development environment restoration.

## Technical Context

**Language/Version**: Bash (POSIX-compatible, macOS-centric), Dart (SDK >=2.14.0 <4.0.0)
**Primary Dependencies**: Flutter CLI, git, curl, sed, awk, pub.dev API
**Storage**: N/A
**Testing**: Manual dry-run verification (`--dry-run`), `flutter analyze`, `flutter pub publish --dry-run`
**Target Platform**: macOS developer workstation
**Project Type**: Federated Flutter plugin (monorepo with 5 active packages)
**Performance Goals**: N/A (developer tooling)
**Constraints**: Must match `zikzak_inappwebview` script conventions; only 3 platform implementations active (android, ios, macos); all versions synchronized on publish
**Scale/Scope**: 5 packages, 4 podspecs, 5 scripts

## Constitution Check

Constitution file is in template state (all placeholders). No gates to enforce.

## Project Structure

### Documentation (this feature)

```text
specs/001-publishing-scripts-macos/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
scripts/
├── prepare_for_publish.sh
├── publish.sh
├── restore_dev_setup.sh
├── revert_publish_changes.sh
└── push_to_master.sh

zikzak_share_handler/                    # Main app-facing package
zikzak_share_handler_platform_interface/ # Platform interface
zikzak_share_handler_android/            # Android implementation
zikzak_share_handler_ios/                # iOS implementation (+ 2 podspecs)
zikzak_share_handler_macos/              # macOS implementation (+ 2 podspecs)
zikzak_share_handler_linux/              # (inactive)
zikzak_share_handler_web/                # (inactive)
zikzak_share_handler_windows/            # (inactive)
```

**Structure Decision**: Flat monorepo with sibling package directories at root, matching `zikzak_inappwebview` layout. Scripts in `scripts/` directory.

## Active Packages (Publish Order)

| Order | Package | Has Podspecs | Depends On |
|-------|---------|-------------|------------|
| 1 | `zikzak_share_handler_platform_interface` | No | flutter, plugin_platform_interface |
| 2 | `zikzak_share_handler_android` | No | platform_interface |
| 3 | `zikzak_share_handler_ios` | Yes (2) | platform_interface |
| 4 | `zikzak_share_handler_macos` | Yes (2) | platform_interface |
| 5 | `zikzak_share_handler` | No | platform_interface, android, ios, macos |

### Podspec Files

| Package | Podspec | Current Version |
|---------|---------|----------------|
| ios | `zikzak_share_handler_ios/ios/zikzak_share_handler_ios.podspec` | 0.0.16 |
| ios | `zikzak_share_handler_ios/ios/Models/zikzak_share_handler_ios_models.podspec` | 0.0.9 |
| macos | `zikzak_share_handler_macos/macos/zikzak_share_handler_macos.podspec` | 0.0.1 |
| macos | `zikzak_share_handler_macos/macos/Models/zikzak_share_handler_macos_models.podspec` | 0.0.1 |
