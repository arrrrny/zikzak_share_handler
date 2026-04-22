# Tasks: Fix macOS Share Handler

**Input**: Design documents from `/specs/002-fix-macos-share/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: No tests explicitly requested in the specification. Test tasks are not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Delete & Recreate Example App)

**Purpose**: Remove the broken example app and create a fresh Flutter project

- [x] T001 Delete existing example directory at `zikzak_share_handler/example/`
- [x] T002 Create new Flutter example project with iOS and macOS platforms at `zikzak_share_handler/example/` using `flutter create --platforms=ios,macos example/`
- [x] T003 Update `zikzak_share_handler/example/pubspec.yaml` to depend on `zikzak_share_handler` via path reference (`../`)
- [x] T004 Write example app Dart code in `zikzak_share_handler/example/lib/main.dart` — call `ShareHandler.instance.getInitialSharedMedia()` on init, listen to `sharedMediaStream`, display shared content and file attachments
- [x] T005 Run `flutter pub get` in `zikzak_share_handler/example/` to resolve dependencies

---

## Phase 2: Foundational (Fix macOS Plugin Core)

**Purpose**: Fix the protocol mismatch that prevents the macOS plugin from receiving URL events. This MUST be completed before any user story work.

**⚠️ CRITICAL**: This is the root cause fix. Without it, no share functionality works on macOS.

- [x] T006 In `zikzak_share_handler_macos/macos/Classes/SwiftShareHandlerMacosPlatform.swift`, replace `application(_:open:)` method (lines 50-56) with `handleOpenURLs(_:) -> Bool` that iterates URLs, checks `hasMatchingSchemePrefix`, and calls `handleUrl(url:setInitialData:false)` for matching URLs, returning `true`
- [x] T007 In `zikzak_share_handler_macos/macos/Classes/SwiftShareHandlerMacosPlatform.swift`, replace `applicationDidFinishLaunching(_:)` method (lines 76-86) with `handleDidFinishLaunching(_:) -> Bool` that reads `NSApplication.launchUserNotificationUserInfoKey` from notification userInfo and calls `handleUrl(url:setInitialData:true)` for matching URLs, returning `true`
- [x] T008 In `zikzak_share_handler_macos/macos/Classes/SwiftShareHandlerMacosPlatform.swift`, remove dead code methods: `applicationShouldHandleReopen(_:hasVisibleWindows:)` (lines 46-48), `application(_:openFile:)` (lines 58-64), `application(_:openFiles:)` (lines 66-74)
- [x] T009 Verify `handleUrl(url:setInitialData:)` and `hasMatchingSchemePrefix(url:)` private methods in `zikzak_share_handler_macos/macos/Classes/SwiftShareHandlerMacosPlatform.swift` are unchanged and correct (read UserDefaults by key, decode SharedMedia, push to eventSink)

**Checkpoint**: Plugin core is fixed. The macOS plugin will now receive URL events via `FlutterAppLifecycleDelegate` protocol.

---

## Phase 3: User Story 1 — Receive shared link on macOS (Priority: P1) 🎯 MVP

**Goal**: macOS share extension captures a shared URL and delivers it to the Flutter app via the event stream

**Independent Test**: Share a URL from Safari to the example app on macOS and verify the URL content appears in the app UI

### Implementation for User Story 1

- [ ] T010 [P] [US1] Configure macOS Runner URL scheme in `zikzak_share_handler/example/macos/Runner/Info.plist` — add `CFBundleURLTypes` array with `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` scheme
- [ ] T011 [P] [US1] Create macOS Runner entitlements at `zikzak_share_handler/example/macos/Runner/DebugProfile.entitlements` — add `com.apple.security.application-groups` with `group.wtf.zikzak.zikzakShareHandlerExample`, keep `com.apple.security.app-sandbox` with value `true`, add `com.apple.security.cs.allow-jit` with value `true`
- [ ] T012 [P] [US1] Create macOS Runner release entitlements at `zikzak_share_handler/example/macos/Runner/Release.entitlements` — add `com.apple.security.application-groups` with `group.wtf.zikzak.zikzakShareHandlerExample`, keep `com.apple.security.app-sandbox` with value `true` (no JIT)
- [ ] T013 [US1] Create macOS ShareExtension directory at `zikzak_share_handler/example/macos/ShareExtension/` with `ShareViewController.swift` that subclasses `ShareHandlerMacosViewController`
- [ ] T014 [US1] Create macOS ShareExtension Info.plist at `zikzak_share_handler/example/macos/ShareExtension/Info.plist` — configure `NSExtensionPointIdentifier` as `com.apple.share-services`, `NSExtensionMainStoryboard` as `MainInterface`, `NSExtensionActivationRule` as SUBQUERY predicate accepting `public.file-url`, `public.image`, `public.text`, `public.movie`, `public.url`
- [ ] T015 [US1] Create macOS ShareExtension entitlements at `zikzak_share_handler/example/macos/ShareExtension/ShareExtension.entitlements` — add `com.apple.security.application-groups` with `group.wtf.zikzak.zikzakShareHandlerExample`, add `com.apple.security.app-sandbox` with value `true`
- [ ] T016 [US1] Create macOS ShareExtension XIB storyboard at `zikzak_share_handler/example/macos/ShareExtension/Base.lproj/ShareViewController.xib` with Send and Cancel buttons wired to the view controller
- [ ] T017 [US1] Create macOS ShareExtension xcconfig files at `zikzak_share_handler/example/macos/ShareExtension/Debug.xcconfig` and `Release.xcconfig` — include Flutter exported headers and framework search paths
- [ ] T018 [US1] Update macOS Podfile at `zikzak_share_handler/example/macos/Podfile` — add nested `ShareExtension` target with `inherit! :search_paths` and `pod "zikzak_share_handler_macos_models"` pointing to the plugin symlink path
- [ ] T019 [US1] Update macOS Xcode project at `zikzak_share_handler/example/macos/Runner.xcodeproj/project.pbxproj` — add ShareExtension target with `PRODUCT_BUNDLE_IDENTIFIER` as `wtf.zikzak.zikzakShareHandlerExample.ShareExtension`, set `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements` for all ShareExtension build configurations, set `REGISTER_APP_GROUPS = YES`, add target dependency from Runner to ShareExtension, add "Embed Foundation Extensions" copy files build phase
- [ ] T020 [US1] Update macOS Runner `AppInfo.xcconfig` at `zikzak_share_handler/example/macos/Runner/Configs/AppInfo.xcconfig` — set `PRODUCT_BUNDLE_IDENTIFIER = wtf.zikzak.zikzakShareHandlerExample`

**Checkpoint**: At this point, sharing a URL from Safari to the example app on macOS should open the app and display the URL in the Flutter UI. Test both cold-start (app not running) and warm-resume (app in background) scenarios.

---

## Phase 4: User Story 2 — Receive shared text on macOS (Priority: P2)

**Goal**: macOS share extension captures shared text and delivers it via the same mechanism

**Independent Test**: Select text in any macOS app, share it to the example app, and verify the text appears

### Implementation for User Story 2

- [ ] T021 [US2] Verify macOS ShareExtension `NSExtensionActivationRule` in `zikzak_share_handler/example/macos/ShareExtension/Info.plist` includes `public.text` UTI conformance (should already be present from T014)
- [ ] T022 [US2] Verify `ShareHandlerMacosViewController.handleText()` in `zikzak_share_handler_macos/macos/Models/Classes/ShareHandlerMacosViewController.swift` correctly extracts text from `NSExtensionItem` attachments and appends to `sharedText` array
- [ ] T023 [US2] Test text sharing end-to-end: select text in Safari, share to example app, verify text appears in `content` field of `SharedMedia`

**Checkpoint**: Text sharing works alongside URL sharing. Both use the same data path (content field of SharedMedia).

---

## Phase 5: User Story 3 — Receive shared files on macOS (Priority: P3)

**Goal**: macOS share extension captures shared files, copies them to the app group container, and delivers paths to Flutter

**Independent Test**: Share an image file from Finder to the example app and verify the file path appears

### Implementation for User Story 3

- [ ] T024 [US3] Verify macOS ShareExtension `NSExtensionActivationRule` in `zikzak_share_handler/example/macos/ShareExtension/Info.plist` includes `public.file-url`, `public.image`, `public.movie` UTI conformances (should already be present from T014)
- [ ] T025 [US3] Verify `ShareHandlerMacosViewController.handleFiles()` in `zikzak_share_handler_macos/macos/Models/Classes/ShareHandlerMacosViewController.swift` correctly copies files to the app group container and creates `SharedAttachment` objects with proper paths
- [ ] T026 [US3] Verify `ShareHandlerMacosViewController.copyFile()` and `getNewFileUrl()` methods in `zikzak_share_handler_macos/macos/Models/Classes/ShareHandlerMacosViewController.swift` correctly resolve shared container paths
- [ ] T027 [US3] Test file sharing end-to-end: share an image from Finder to example app, verify attachment path appears and file is accessible

**Checkpoint**: File sharing works. All three content types (URLs, text, files) are functional on macOS.

---

## Phase 6: iOS Example App Configuration

**Purpose**: Recreate the iOS share extension configuration for the new example app to maintain iOS functionality

- [ ] T028 [P] Configure iOS Runner Info.plist at `zikzak_share_handler/example/ios/Runner/Info.plist` — add `CFBundleURLTypes` with `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` scheme, add `CFBundleDocumentTypes` for share-compatible types (`public.file-url`, `public.image`, `public.text`, `public.movie`, `public.url`, `public.data`), add `NSUserActivityTypes` with `INSendMessageIntent`
- [ ] T029 [P] Create iOS Runner entitlements at `zikzak_share_handler/example/ios/Runner/Runner.entitlements` — add `com.apple.security.application-groups` with `group.wtf.zikzak.zikzakShareHandlerExample`
- [ ] T030 Create iOS ShareExtension directory at `zikzak_share_handler/example/ios/ShareExtension/` with `ShareViewController.swift` that subclasses `ShareHandlerIosViewController`
- [ ] T031 Create iOS ShareExtension Info.plist at `zikzak_share_handler/example/ios/ShareExtension/Info.plist` — configure `NSExtensionPointIdentifier` as `com.apple.share-services`, `NSExtensionMainStoryboard` as `MainInterface`, `NSExtensionActivationRule` as SUBQUERY predicate, `IntentsSupported` with `INSendMessageIntent`
- [ ] T032 Create iOS ShareExtension entitlements at `zikzak_share_handler/example/ios/ShareExtension/ShareExtension.entitlements` — add `com.apple.security.application-groups` with `group.wtf.zikzak.zikzakShareHandlerExample`
- [ ] T033 Create iOS ShareExtension storyboard at `zikzak_share_handler/example/ios/ShareExtension/Base.lproj/MainInterface.storyboard` — empty storyboard with transparent ShareViewController
- [ ] T034 Create iOS ShareExtension xcconfig files at `zikzak_share_handler/example/ios/ShareExtension/Debug.xcconfig` and `Release.xcconfig`
- [ ] T035 Update iOS Podfile at `zikzak_share_handler/example/ios/Podfile` — add nested `ShareExtension` target with `inherit! :search_paths` and `pod "zikzak_share_handler_ios_models"` pointing to the plugin symlink path
- [ ] T036 Update iOS Xcode project at `zikzak_share_handler/example/ios/Runner.xcodeproj/project.pbxproj` — add ShareExtension target with `PRODUCT_BUNDLE_IDENTIFIER` as `wtf.zikzak.zikzakShareHandlerExample.ShareExtension`, set `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements`, add target dependency from Runner to ShareExtension, add "Embed App Extensions" copy files build phase
- [ ] T037 Update iOS Runner `AppInfo.xcconfig` at `zikzak_share_handler/example/ios/Flutter/Generated.xcconfig` or equivalent — ensure `PRODUCT_BUNDLE_IDENTIFIER = wtf.zikzak.zikzakShareHandlerExample`

**Checkpoint**: iOS example app has a working share extension configuration. Test sharing a URL from Safari on iOS simulator.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final verification, cleanup, and cross-platform validation

- [ ] T038 Delete stale widget test at `zikzak_share_handler/example/test/widget_test.dart` and create a new basic widget test that verifies the app renders with expected UI elements
- [ ] T039 Build macOS example app: `cd zikzak_share_handler/example && flutter build macos` — verify no compilation errors
- [ ] T040 Build iOS example app: `cd zikzak_share_handler/example && flutter build ios --no-codesign` — verify no compilation errors
- [ ] T041 Run `flutter pub get` and `flutter analyze` in `zikzak_share_handler_macos/` to verify no lint issues in the modified plugin code
- [ ] T042 Run `flutter test` in `zikzak_share_handler_macos/` to verify existing plugin tests still pass
- [ ] T043 Run quickstart.md validation: verify all manual testing steps described in `specs/002-fix-macos-share/quickstart.md` are actionable

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: No dependency on Phase 1 — can start in parallel (plugin fix is independent of example app)
- **User Story 1 (Phase 3)**: Depends on Phase 1 AND Phase 2 completion — needs both the fixed plugin and the example app skeleton
- **User Story 2 (Phase 4)**: Depends on Phase 3 — verifies text handling works with the same infrastructure
- **User Story 3 (Phase 5)**: Depends on Phase 3 — verifies file handling works with the same infrastructure
- **iOS Configuration (Phase 6)**: Can run in parallel with Phases 3-5 — independent platform
- **Polish (Phase 7)**: Depends on all other phases being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (plugin fix). No dependencies on other stories.
- **User Story 2 (P2)**: Logically depends on US1 infrastructure but technically the same code path. Verification only.
- **User Story 3 (P3)**: Logically depends on US1 infrastructure but technically the same code path. Verification only.

### Within Each User Story

- Info.plist and entitlements can be created in parallel
- Xcode project modifications depend on all files being created first
- End-to-end testing is the final step

### Parallel Opportunities

- Phase 1 (Setup) and Phase 2 (Plugin Fix) can run in parallel
- T010, T011, T012 can run in parallel (different entitlements files)
- Phase 6 (iOS Configuration) can run entirely in parallel with Phases 3-5 (macOS)
- T028, T029 can run in parallel (different iOS config files)

---

## Parallel Example: User Story 1

```bash
# Launch entitlements and Info.plist tasks together:
Task T010: "Configure macOS Runner URL scheme in Info.plist"
Task T011: "Create macOS Runner DebugProfile entitlements"
Task T012: "Create macOS Runner Release entitlements"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (delete & recreate example app)
2. Complete Phase 2: Foundational (fix plugin protocol mismatch)
3. Complete Phase 3: User Story 1 (macOS URL sharing)
4. **STOP and VALIDATE**: Share a URL from Safari to the example app on macOS
5. If working, the core fix is confirmed — US2 and US3 are verification only

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test URL sharing → **MVP complete!**
3. Verify User Story 2 → Confirm text sharing works (same code path)
4. Verify User Story 3 → Confirm file sharing works (same code path)
5. Add iOS Configuration → Cross-platform support
6. Polish → Build verification, analysis, tests

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- User Stories 2 and 3 are primarily verification tasks since the share extension already handles all content types — the fix in Phase 2 enables the entire pipeline
- The Xcode project (pbxproj) modifications are the most complex tasks — they require careful UUID management and build phase configuration
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
