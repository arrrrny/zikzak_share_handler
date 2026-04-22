# Quickstart: Publishing Scripts

**Feature**: 001-publishing-scripts-macos
**Date**: 2026-04-21

## Prerequisites

- Flutter SDK installed and on PATH
- Git repo on `master` branch with clean working tree
- pub.dev credentials configured (`dart pub login`)
- All packages use path dependencies (development mode)

## Workflow

### 1. Prepare for publishing

```bash
./scripts/prepare_for_publish.sh 0.0.32
```

This will:
- Create branch `publish-0.0.32`
- Update version in all 5 package pubspec.yaml files
- Update version in 4 podspec files
- Convert path dependencies to `^0.0.32`
- Generate changelogs from git history
- Commit all changes

### 2. Publish to pub.dev

```bash
./scripts/publish.sh
```

This will:
- Publish packages in dependency order (platform_interface → android → ios → macos → main)
- Verify each dependency is available on pub.dev before publishing dependents
- Run `flutter analyze` and `--dry-run` before each publish
- Create and push git tag after all packages are published

### 3. Merge to master and push

```bash
./scripts/push_to_master.sh
```

This will:
- Merge `publish-0.0.32` into `master`
- Create version tag `0.0.32`
- Push to remote

### 4. Restore development setup

```bash
./scripts/restore_dev_setup.sh
```

This will:
- Convert all versioned dependencies back to path dependencies
- Run `flutter pub get` on all packages

## Abort / Rollback

If you need to discard publish preparation:

```bash
./scripts/revert_publish_changes.sh
```

This switches back to `master`, optionally deletes the publish branch, and restores dev dependencies.
