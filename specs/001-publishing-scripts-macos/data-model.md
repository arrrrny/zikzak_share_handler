# Data Model: Publishing Scripts

**Feature**: 001-publishing-scripts-macos
**Date**: 2026-04-21

## Entities

### Package

Represents a federated plugin sub-package in the monorepo.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Directory/package name (e.g., `zikzak_share_handler_android`) |
| directory | path | Relative path from repo root (same as `name`) |
| publish_order | int | 1-based ordering for publish sequence |
| has_podspecs | boolean | Whether package has Cocoa podspecs to update |
| podspec_paths | path[] | Relative paths to podspec files |
| dependencies | string[] | Names of other `zikzak_share_handler_*` packages it depends on |

### Active Packages

```
zikzak_share_handler_platform_interface
  publish_order: 1
  has_podspecs: false
  dependencies: []

zikzak_share_handler_android
  publish_order: 2
  has_podspecs: false
  dependencies: [zikzak_share_handler_platform_interface]

zikzak_share_handler_ios
  publish_order: 3
  has_podspecs: true
  podspec_paths:
    - zikzak_share_handler_ios/ios/zikzak_share_handler_ios.podspec
    - zikzak_share_handler_ios/ios/Models/zikzak_share_handler_ios_models.podspec
  dependencies: [zikzak_share_handler_platform_interface]

zikzak_share_handler_macos
  publish_order: 4
  has_podspecs: true
  podspec_paths:
    - zikzak_share_handler_macos/macos/zikzak_share_handler_macos.podspec
    - zikzak_share_handler_macos/macos/Models/zikzak_share_handler_macos_models.podspec
  dependencies: [zikzak_share_handler_platform_interface]

zikzak_share_handler
  publish_order: 5
  has_podspecs: false
  dependencies: [
    zikzak_share_handler_platform_interface,
    zikzak_share_handler_android,
    zikzak_share_handler_ios,
    zikzak_share_handler_macos
  ]
```

### Dependency Graph

```
platform_interface (1)
    ├── android (2)
    ├── ios (3)
    └── macos (4)
         \  (all above)
          main package (5)
```

### Dependency Format States

Path dependencies (development mode):
```yaml
zikzak_share_handler_platform_interface:
  path: ../zikzak_share_handler_platform_interface
```

Versioned dependencies (publish mode):
```yaml
zikzak_share_handler_platform_interface: ^X.Y.Z
```

### Script Data Flow

```
prepare_for_publish.sh
  Input: version string (or auto-detect from main pubspec.yaml)
  Mutates:
    - */pubspec.yaml (version + dependencies)
    - */*.podspec (version in 4 files)
    - */CHANGELOG.md (prepend new version entry)
  Output: git branch `publish-X.Y.Z` with committed changes

publish.sh
  Input: none (reads versions from pubspec.yaml)
  Validates: flutter analyze, dry-run publish
  Verifies: dependency availability on pub.dev (retry with backoff)
  Output: packages published to pub.dev in order

restore_dev_setup.sh
  Input: none
  Mutates: */pubspec.yaml (converts versioned → path deps)
  Output: path dependencies restored, pub get run on all packages

revert_publish_changes.sh
  Input: none (interactive confirmation)
  Mutates: git state (switch to master, optionally delete publish branch)
  Output: repo on master with dev setup restored

push_to_master.sh
  Input: none (reads version from branch name)
  Mutates: git state (merge to master, create tag, push)
  Output: master branch updated with tag pushed to remote
```
