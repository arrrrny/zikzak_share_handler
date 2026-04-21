# Feature Specification: Publishing Scripts and macOS Platform Support

**Feature Branch**: `001-publishing-scripts-macos`
**Created**: 2026-04-15
**Status**: Draft
**Input**: User description: "This is my package and ios and android works perfectly. I want you to first check the Developer/zikzak_inappwebview thats another package of mine. I have a sane process of publishing packages there since they depend on each other. implement the same publishing scripts here. and I never used the macos or other implementations. so especially I need macos to work. check current implementation and test it"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publishing Workflow with Scripts (Priority: P1)

As a package maintainer, I need a set of publishing scripts (prepare, publish, restore, revert, push-to-master) that mirror the established workflow in zikzak_inappwebview, so that I can reliably prepare, publish, and revert multi-package federated plugin releases with correct dependency ordering and version synchronization across all sub-packages.

**Why this priority**: Without publishing scripts, the package cannot be released. This is the foundational capability that enables all other work.

**Independent Test**: Can be fully tested by running the scripts in dry-run mode and verifying that versions are updated, path dependencies are converted to versioned, and changelogs are generated correctly.

**Acceptance Scenarios**:

1. **Given** a monorepo with 8 federated packages using path dependencies, **When** the maintainer runs `prepare_for_publish.sh <version>`, **Then** all pubspec.yaml files are updated to the new version, path dependencies are converted to versioned (`^X.Y.Z`) dependencies, changelogs are generated, and a publish branch is created
2. **Given** a prepared publish branch with versioned dependencies, **When** the maintainer runs `publish.sh`, **Then** packages are published in dependency order (platform_interface first, then platform implementations, then main package), with dependency availability verification between each step
3. **Given** a completed or aborted publish, **When** the maintainer runs `restore_dev_setup.sh`, **Then** all dependencies are converted back to path dependencies for local development
4. **Given** a publish branch that needs to be discarded, **When** the maintainer runs `revert_publish_changes.sh`, **Then** the publish branch is deleted and the repo returns to the main branch with development dependencies restored
5. **Given** a successful publish, **When** the maintainer runs `push_to_master.sh`, **Then** the publish branch is merged into master, tagged with the version, and pushed to remote

---

### User Story 2 - macOS Platform Implementation (Priority: P1)

As a Flutter developer using this plugin, I need the macOS platform implementation to actually handle shared content (text, files, URLs) received from other macOS applications, so that my app can receive shares on macOS just like it does on iOS and Android.

**Why this priority**: The user explicitly stated macOS must work. The current macOS implementation is a stub (only `getPlatformVersion`) that does not implement any actual share handling functionality.

**Independent Test**: Can be tested by building a Flutter macOS app with this plugin, sharing text/files from another macOS app, and verifying the shared content is received via the stream and initial media APIs.

**Acceptance Scenarios**:

1. **Given** a macOS Flutter app with the plugin configured, **When** another app shares text to it, **Then** the text content is received via `getInitialSharedMedia()` or `sharedMediaStream`
2. **Given** a macOS Flutter app with the plugin configured, **When** another app shares a file (image, video, document) to it, **Then** the file attachment with correct path and type is received
3. **Given** the macOS platform package, **When** it is built for macOS, **Then** it compiles without errors and registers correctly as a Flutter plugin on macOS
4. **Given** the macOS plugin registration, **When** the app launches, **Then** `ShareHandlerMacosPlatform` registers itself as the platform implementation via `registerWith()`

---

### User Story 3 - Enable macOS in Federated Plugin Setup (Priority: P2)

As a package maintainer, I need macOS to be enabled (uncommented) in the main app-facing package's pubspec.yaml plugin platforms and dependencies, so that consumers of the package get macOS support automatically when they add the main package.

**Why this priority**: Without enabling macOS in the main package, users will not get macOS support even if the macOS implementation is complete.

**Independent Test**: Can be tested by adding `zikzak_share_handler` as a dependency to a Flutter macOS project and verifying it builds and resolves correctly.

**Acceptance Scenarios**:

1. **Given** the main `zikzak_share_handler` pubspec.yaml, **When** macOS is enabled, **Then** the `macos` platform entry and `zikzak_share_handler_macos` dependency are active (not commented out)
2. **Given** a Flutter app depending on `zikzak_share_handler`, **When** building for macOS, **Then** the macOS platform implementation is correctly resolved and the app builds

---

### User Story 4 - Enable Other Platforms (Web, Windows, Linux) (Priority: P3)

As a package maintainer, I need the web, windows, and linux platform implementations to be enabled in the main package, following the same pattern as macOS, so that users get full cross-platform support.

**Why this priority**: These platforms are secondary to macOS (user's explicit ask) but should be enabled for completeness.

**Independent Test**: Can be tested by building for each respective platform and verifying the plugin loads.

**Acceptance Scenarios**:

1. **Given** the main package pubspec.yaml, **When** all platforms are enabled, **Then** web, windows, and linux platform entries and dependencies are active
2. **Given** each platform implementation package, **When** building for that platform, **Then** the plugin registers and initializes correctly

---

### Edge Cases

- What happens when `prepare_for_publish.sh` is run with a version that already exists on pub.dev?
- What happens when `publish.sh` fails mid-way (e.g., third package fails to publish)?
- What happens when macOS shares are received while the app is not yet fully launched?
- What happens when the macOS platform receives unsupported file types?
- What happens if `SharedAttachment.decode` receives data on macOS (currently has `Platform.isIOS` check only)?
- What happens when path dependencies are restored but some packages have been restructured?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `scripts/prepare_for_publish.sh` script MUST update version numbers across all packages (platform_interface, android, ios, web, macos, windows, linux, and main) to the specified version
- **FR-002**: The `scripts/prepare_for_publish.sh` script MUST convert all path dependencies to versioned dependencies (`^X.Y.Z`) in all pubspec.yaml files
- **FR-003**: The `scripts/prepare_for_publish.sh` script MUST update iOS and macOS podspec files with the new version
- **FR-004**: The `scripts/prepare_for_publish.sh` script MUST generate changelog entries from git history
- **FR-005**: The `scripts/prepare_for_publish.sh` script MUST create a `publish-X.Y.Z` git branch and commit changes
- **FR-006**: The `scripts/publish.sh` script MUST publish packages in correct dependency order: platform_interface first, then platform implementations, then main package
- **FR-007**: The `scripts/publish.sh` script MUST verify each dependency is available on pub.dev before publishing dependent packages, with retry logic
- **FR-008**: The `scripts/publish.sh` script MUST run `flutter analyze` and `flutter pub publish --dry-run` before actual publish
- **FR-009**: The `scripts/restore_dev_setup.sh` script MUST convert all versioned dependencies back to path dependencies for local development
- **FR-010**: The `scripts/revert_publish_changes.sh` script MUST switch back to the main branch and optionally delete the publish branch
- **FR-011**: The `scripts/push_to_master.sh` script MUST merge the publish branch into master, create a version tag, and push to remote
- **FR-012**: The macOS platform implementation MUST implement `registerWith()` to register itself as the `ShareHandlerPlatform` instance
- **FR-013**: The macOS platform implementation MUST implement `getInitialSharedMedia()`, `recordSentMessage()`, `resetInitialSharedMedia()`, and `sharedMediaStream` with full native backing (not stubs)
- **FR-013a**: The macOS native layer MUST handle incoming shared content (text, files, URLs) via macOS share mechanisms and forward them to Flutter through method channels and event channels, matching the iOS implementation pattern
- **FR-014**: The macOS plugin MUST use the correct method channel name compatible with the platform interface
- **FR-015**: The macOS pubspec.yaml MUST correctly declare the `macos` platform (not `ios`) in the flutter.plugin.platforms section
- **FR-016**: The `SharedAttachment.decode` MUST handle macOS paths correctly (currently only decodes URI on iOS, should also handle macOS)
- **FR-017**: The macOS podspec MUST have the correct pod name matching the pubspec package name
- **FR-018**: The main `zikzak_share_handler` pubspec.yaml MUST enable macOS (and other platform) entries in both plugin platforms and dependencies sections

### Key Entities

- **Publishing Scripts**: Set of 5 shell scripts (`prepare_for_publish.sh`, `publish.sh`, `restore_dev_setup.sh`, `revert_publish_changes.sh`, `push_to_master.sh`) that manage the release lifecycle
- **Federated Package Structure**: 8 packages (main, platform_interface, android, ios, macos, web, windows, linux) with dependency relationships
- **ShareHandlerMacosPlatform**: The macOS-specific implementation of `ShareHandlerPlatform` that bridges native macOS share handling to Flutter
- **SharedMedia/SharedAttachment**: Data models that carry shared content information across all platforms

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 5 publishing scripts execute without errors in their respective workflows (prepare, publish, restore, revert, push)
- **SC-002**: Package versions are synchronized across all 8 sub-packages when prepared for publishing
- **SC-003**: Path dependencies are correctly converted to versioned and back without data loss
- **SC-004**: macOS Flutter app builds successfully with the plugin and receives shared content
- **SC-005**: All platform implementations compile and pass `flutter analyze` without errors
- **SC-006**: The publishing dependency order ensures no publish fails due to unresolved internal dependencies

## Clarifications

### Session 2026-04-15

- Q: What should happen with the stashed unverified modernization changes (iOS SDK bump, FlutterSceneLifeCycleDelegate, dev dep switches)? → A: Discard stash entirely; redo all modernization properly during implementation with proper testing and verification.
- Q: What depth of macOS implementation is needed? → A: Full implementation matching iOS — share extensions, URL handling, stream support, all platform interface methods fully functional.

## Assumptions

- The publishing workflow follows the exact same conventions as `zikzak_inappwebview` (same script names, same branching strategy, same version sync approach)
- The macOS share handling should use the same method channel and pigeon-based API as iOS since macOS shares Cocoa/Foundation framework with iOS
- The `Platform.isIOS` check in `SharedAttachment.decode` should be extended to `Platform.isIOS || Platform.isMacOS` for URI decoding
- The main branch is called `master` (consistent with inappwebview setup)
- Package versions are synchronized (all packages get the same version) during publish
- The macOS native implementation should handle incoming shares via the macOS app lifecycle, similar to how iOS handles them
- Web, Windows, and Linux platform implementations are lower priority but should be enabled alongside macOS
- All previously stashed modernization work (SDK bumps, scene lifecycle changes, dep switches) will be discarded and redone from scratch as part of this feature with proper verification
