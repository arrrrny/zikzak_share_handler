# Tasks: Publishing Scripts and macOS Platform Support

**Input**: Design documents from `/specs/001-publishing-scripts-macos/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Per user directive, macOS implementation (US2) is done FIRST as the modernization playground.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fix existing macOS package configuration and prepare shared code

- [x] T001 Fix `zikzak_share_handler_macos/pubspec.yaml` — change `platforms: ios:` to `platforms: macos:`, add `implements: zikzak_share_handler`, add `dartPluginClass: ShareHandlerMacosPlatform`, switch `zikzak_share_handler_platform_interface` dep from versioned `^0.0.7` to `path: ../zikzak_share_handler_platform_interface`
- [x] T002 [P] Rename `zikzak_share_handler_macos/macos/zikzak_share_handler.podspec` to `zikzak_share_handler_macos/macos/zikzak_share_handler_macos.podspec` — update `s.name` to `zikzak_share_handler_macos`, keep `s.dependency 'FlutterMacOS'`, `s.platform = :osx, '10.11'`, `s.swift_version = '5.0'`
- [x] T003 [P] Fix `SharedAttachment.decode` in `zikzak_share_handler_platform_interface/lib/src/data/messages.dart` — extend `Platform.isIOS` check at line 25 to `Platform.isIOS || Platform.isMacOS` so macOS paths are also URI-decoded
- [x] T004 [P] Create Obj-C bridge header `zikzak_share_handler_macos/macos/Classes/ShareHandlerMacosPlugin.h` — import `FlutterMacOS/FlutterMacOS.h`, declare `ShareHandlerMacosPlatform` conforming to `FlutterPlugin`
- [x] T005 [P] Create Obj-C bridge implementation `zikzak_share_handler_macos/macos/Classes/ShareHandlerMacosPlugin.m` — import header and Swift bridging header (`zikzak_share_handler_macos-Swift.h`), forward `+registerWithRegistrar:` to `[SwiftShareHandlerMacosPlatform registerWithRegistrar:registrar]`

**Checkpoint**: macOS package configuration is correct, podspec matches conventions, SharedAttachment handles macOS

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the native shared models and Pigeon API that both the main plugin and Share Extension depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Create shared models directory structure: `zikzak_share_handler_macos/macos/Models/Classes/` and create `zikzak_share_handler_macos/macos/Models/zikzak_share_handler_macos_models.podspec` — pure Foundation/AppKit pod with `s.source_files = 'Classes/**/*'`, NO Flutter dependency, `s.platform = :osx, '10.11'`, `s.swift_version = '5.0'`
- [x] T007 [P] Create `zikzak_share_handler_macos/macos/Models/Classes/SharedModels.swift` — port from iOS `SharedModels.swift`: define `SharedAttachmentType` enum (image=0, video=1, audio=2, file=3), `SharedAttachment` class with `path`/`type` and `toDictionary()`/`fromMap()`, `SharedMedia` class with all fields and `toDictionary()`/`fromMap()`/`encode()`/`decode()`. Use AppKit/Foundation only (no UIKit)
- [x] T008 Create Pigeon API adapter `zikzak_share_handler_macos/macos/Classes/ShareHandlerApi.swift` — port from iOS `ShareHandlerApi.swift`: custom codec (`ShareHandlerApiCodecReaderWriter`) with type IDs 128=SharedAttachment/129=SharedMedia, `ShareHandlerApi` protocol with `getInitialSharedMedia`/`recordSentMessage`/`resetInitialSharedMedia`, `ShareHandlerApiSetup()` function registering BasicMessageChannels. Import `FlutterMacOS` and `zikzak_share_handler_macos_models`
- [x] T009 Update main podspec `zikzak_share_handler_macos/macos/zikzak_share_handler_macos.podspec` to add dependency on models pod: `s.dependency 'zikzak_share_handler_macos_models'`, keep `s.source_files = 'Classes/**/*'`

**Checkpoint**: Shared models and Pigeon API are ready, both main app and share extension can use them

---

## Phase 3: User Story 2 - macOS Platform Implementation (Priority: P1) 🎯 MVP

**Goal**: Full macOS share handling — native plugin receives shared URLs from other apps via Share Extension, forwards to Flutter via stream and initial media APIs. Example app prints shared URLs.

**Independent Test**: Build example app on macOS, share a URL from Safari via system share sheet, verify URL prints in example app console

### Implementation for User Story 2

- [x] T010 [US2] Rewrite Dart platform implementation in `zikzak_share_handler_macos/lib/src/zikzak_share_handler_macos.dart` — implement `ShareHandlerMacosPlatform extends ShareHandlerPlatform` with `registerWith()`, `getInitialSharedMedia()` via Pigeon `ShareHandlerApi`, `recordSentMessage()`, `resetInitialSharedMedia()`, `sharedMediaStream` via EventChannel `wtf.zikzak.zikzak_share_handler/sharedMediaStream`. Match `ShareHandlerIosPlatform` pattern exactly
- [x] T011 [US2] Rewrite native Swift plugin `zikzak_share_handler_macos/macos/Classes/SwiftShareHandlerMacosPlatform.swift` — singleton pattern, `register(with:)` sets up Pigeon API via `ShareHandlerApiSetup()`, EventChannel on `wtf.zikzak.zikzak_share_handler/sharedMediaStream`, `registrar.addMethodCallDelegate()`. Implement `NSApplicationDelegate` methods: `application(_:openFile:)`, `application(_:openUrls:)` for URL handling. Implement `handleUrl(url:setInitialData:)` to read App Group UserDefaults, decode SharedMedia JSON, fire eventSink. Implement `FlutterStreamHandler` conformance. No SceneDelegate needed on macOS
- [x] T012 [US2] Create Share Extension view controller `zikzak_share_handler_macos/macos/Models/Classes/ShareHandlerMacosViewController.swift` — subclass `NSViewController`, port from iOS `ShareHandlerIosViewController`: `viewDidLoad()` → `loadIds()` → `loadInputItems()`, iterate `NSExtensionContext.inputItems` extracting URL-type `NSItemProvider` items (UTI: `public.url`, `public.file-url`), build `SharedMedia` with `content` field, `redirectToHostApp()` serializes to JSON → writes to `UserDefaults(suiteName: appGroupId)` → opens custom URL scheme via `NSWorkspace.shared.open(url)`, calls `extensionContext?.completeRequest(returningItems:)`. Use `NSViewController` not `UIViewController`
- [x] T013 [US2] Update barrel export `zikzak_share_handler_macos/lib/zikzak_share_handler_macos.dart` — ensure it exports `src/zikzak_share_handler_macos.dart`

**Checkpoint**: macOS platform package compiles with full share handling (URL sharing via Share Extension)

---

## Phase 4: User Story 3 - Enable macOS in Federated Plugin Setup (Priority: P2)

**Goal**: macOS is enabled in the main app-facing package so consumers get macOS support automatically

**Independent Test**: Add `zikzak_share_handler` as dependency to a Flutter macOS project, verify it resolves and builds

### Implementation for User Story 3

- [ ] T014 [US3] Enable macOS in `zikzak_share_handler/pubspec.yaml` — uncomment `macos: default_package: zikzak_share_handler_macos` under `flutter.plugin.platforms`, uncomment `zikzak_share_handler_macos:` dependency with `path: ../zikzak_share_handler_macos` under `dependencies`
- [ ] T015 [US3] Create macOS example app structure — add macOS Share Extension target to `zikzak_share_handler/example/`: create `example/macos/ShareExtension/` directory with `ShareViewController.swift` (subclass `ShareHandlerMacosViewController`), `Info.plist` with `NSExtension` config (activation rules for URLs: `public.url`, `public.file-url`), `ShareExtension.entitlements` with app group, `Base.lproj/MainInterface.storyboard` (blank transparent macOS storyboard)
- [ ] T016 [US3] Configure example app entitlements in `zikzak_share_handler/example/macos/Runner/DebugProfile.entitlements` and `Release.entitlements` — add `com.apple.security.app-groups` with matching group ID (e.g., `group.wtf.zikzak.zikzak-share-handler-example`)
- [ ] T017 [US3] Configure example app URL scheme in `zikzak_share_handler/example/macos/Runner/Info.plist` — add `CFBundleURLTypes` with scheme `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)`
- [ ] T018 [US3] Update example app `main.dart` in `zikzak_share_handler/example/lib/main.dart` — minimal app that initializes `ShareHandler.instance.getInitialSharedMedia()` and listens to `ShareHandler.instance.sharedMediaStream`, printing received URLs to console
- [ ] T019 [US3] Update example Podfile `zikzak_share_handler/example/macos/Podfile` — add ShareExtension target importing models pod: `target 'ShareExtension' do ... pod "zikzak_share_handler_macos_models", :path => ".symlinks/plugins/zikzak_share_handler_macos/macos/Models" ... end`
- [ ] T020 [US3] Build and verify: `cd zikzak_share_handler/example && flutter pub get && flutter run -d macos` — app launches, share URL from Safari via File→Share, verify URL prints in console

**Checkpoint**: macOS fully enabled, example app receives and prints shared URLs from Safari

---

## Phase 5: User Story 1 - Publishing Workflow with Scripts (Priority: P1)

**Goal**: 5 publishing scripts matching zikzak_inappwebview workflow for reliable multi-package releases

**Independent Test**: Run `prepare_for_publish.sh` in dry-run, verify versions update and path deps convert to versioned; run `restore_dev_setup.sh` and verify path deps restored

### Implementation for User Story 1

- [x] T021 [US1] Create `scripts/prepare_for_publish.sh` — port from `zikzak_inappwebview/scripts/prepare_for_publish.sh`: version arg detection, semver validation, `publish-$VERSION` branch creation, update 5 active packages' `pubspec.yaml` versions, update iOS podspecs (2) and macOS podspecs (2), convert path deps to versioned (`^$VERSION`) via `convert_path_to_versioned()`, generate changelog from git commits, update all CHANGELOG.md files, commit. Package list: `zikzak_share_handler_platform_interface`, `zikzak_share_handler_android`, `zikzak_share_handler_ios`, `zikzak_share_handler_macos`, `zikzak_share_handler`
- [x] T022 [US1] Create `scripts/publish.sh` — port from `zikzak_inappwebview/scripts/publish.sh`: publish packages in dependency order (platform_interface → android → ios → macos → main), check pub.dev availability, verify dependency resolution with retry logic (30 retries × 30s), run `flutter pub get` + `dart format` + `flutter analyze` + `flutter pub publish --dry-run` before each publish, create and push git tag from main package version
- [x] T023 [US1] Create `scripts/restore_dev_setup.sh` — port from `zikzak_inappwebview/scripts/restore_dev_setup.sh`: convert all versioned `zikzak_share_handler_*` deps back to path deps in all 5 active packages, run `flutter pub get` on all packages, verify with nuclear clean option and verification checks. Adapt package names from inappwebview to share_handler
- [x] T024 [P] [US1] Create `scripts/revert_publish_changes.sh` — port from `zikzak_inappwebview/scripts/revert_publish_changes.sh`: check for publish branch, confirm revert, discard uncommitted changes, checkout master, optionally delete publish branch, run `restore_dev_setup.sh`
- [x] T025 [P] [US1] Create `scripts/push_to_master.sh` — port from `zikzak_inappwebview/scripts/push_to_master.sh`: detect version from branch name, confirm uncommitted changes, checkout master, pull latest, merge publish branch, create version tag, push to origin master + tag, optionally delete publish branch
- [x] T026 [US1] Make all scripts executable: `chmod +x scripts/*.sh`

**Checkpoint**: All 5 publishing scripts work, can prepare/restore/revert/publish federated packages

---

## Phase 6: User Story 4 - Enable Other Platforms (Priority: P3)

**Goal**: Web, Windows, Linux platforms enabled in main package

**Independent Test**: Verify each platform's pubspec is valid and main package resolves with all platforms enabled

### Implementation for User Story 4

- [ ] T027 [P] [US4] Enable web in `zikzak_share_handler/pubspec.yaml` — uncomment `web: default_package: zikzak_share_handler_web` and `zikzak_share_handler_web:` path dependency
- [ ] T028 [P] [US4] Enable windows in `zikzak_share_handler/pubspec.yaml` — uncomment `windows: default_package: zikzak_share_handler_windows` and `zikzak_share_handler_windows:` path dependency
- [ ] T029 [P] [US4] Enable linux in `zikzak_share_handler/pubspec.yaml` — uncomment `linux: default_package: zikzak_share_handler_linux` and `zikzak_share_handler_linux:` path dependency

**Checkpoint**: All platforms enabled, `flutter pub get` resolves correctly

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [ ] T030 Run `flutter analyze` on all 8 packages — verify zero errors
- [ ] T031 Run `flutter pub get` + build verification on example app for macOS
- [ ] T032 Validate `quickstart.md` instructions end-to-end: setup → build → share URL from Safari → verify print
- [ ] T033 Delete git stash `modernization-attempts-and-dev-setup-unverified` (the discarded changes)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US2 macOS Platform (Phase 3)**: Depends on Phase 2 — core implementation
- **US3 Enable macOS (Phase 4)**: Depends on Phase 3 — needs working macOS platform
- **US1 Publishing Scripts (Phase 5)**: Depends on Phase 4 — needs all platforms enabled for scripts to handle them
- **US4 Other Platforms (Phase 6)**: Depends on Phase 4 — needs macOS pattern established
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundation: shared models, Pigeon API)
    ↓
Phase 3 (US2: macOS platform impl)  ← MVP TARGET
    ↓
Phase 4 (US3: enable macOS in main package + example app)
    ↓
Phase 5 (US1: publishing scripts) ← can partially parallel with Phase 6
    ↓
Phase 6 (US4: enable other platforms)
    ↓
Phase 7 (Polish)
```

### Within Each User Story

- Configuration/fixes before implementation
- Models/podspecs before Swift code
- Native implementation before Dart integration
- Build verification after each phase

### Parallel Opportunities

- T002, T003, T004, T005 can all run in parallel (Phase 1)
- T007 can run in parallel with T008 (Phase 2 - different files)
- T010 and T012 can run in parallel (Phase 3 - Dart vs native share extension)
- T024 and T025 can run in parallel (Phase 5 - independent scripts)
- T027, T028, T029 can run in parallel (Phase 6 - different platform lines in same file, but separate edits)

---

## Parallel Example: Phase 3 (US2 - macOS Platform)

```bash
# Dart side and native share extension can be written in parallel:
Task T010: "Rewrite Dart platform in zikzak_share_handler_macos/lib/src/zikzak_share_handler_macos.dart"
Task T012: "Create Share Extension VC in zikzak_share_handler_macos/macos/Models/Classes/ShareHandlerMacosViewController.swift"

# Then sequential:
Task T011: "Rewrite Swift plugin (depends on T010 pattern + T012 models)"
Task T013: "Update barrel export (depends on T010)"
```

## Parallel Example: Phase 1 (Setup)

```bash
# All four tasks touch different files:
Task T002: "Rename podspec in zikzak_share_handler_macos/macos/"
Task T003: "Fix SharedAttachment in zikzak_share_handler_platform_interface/lib/src/data/messages.dart"
Task T004: "Create Obj-C header in zikzak_share_handler_macos/macos/Classes/"
Task T005: "Create Obj-C impl in zikzak_share_handler_macos/macos/Classes/"
```

---

## Implementation Strategy

### MVP First (US2 + US3 = macOS working)

1. Complete Phase 1: Setup (fix configs, podspec, SharedAttachment)
2. Complete Phase 2: Foundation (shared models, Pigeon API)
3. Complete Phase 3: US2 macOS platform (native plugin + share extension)
4. Complete Phase 4: US3 enable macOS (example app, build & test)
5. **STOP and VALIDATE**: Share URL from Safari → prints in example app
6. This is the working macOS modernization playground

### Incremental Delivery

1. Setup + Foundation → configs fixed, shared code ready
2. Add US2 → macOS platform compiles with full share handling
3. Add US3 → example app works, URL sharing verified end-to-end (MVP!)
4. Add US1 → publishing scripts for releasing packages
5. Add US4 → all platforms enabled for completeness

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US2 (macOS platform) implemented before US1 (publishing scripts) per user directive
- URL sharing first per user directive — other media types (images, files) are incremental additions later
- The macOS implementation serves as the modernization playground for patterns to backport to iOS
- All scripts ported from `zikzak_inappwebview/scripts/` with package name substitutions only
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
