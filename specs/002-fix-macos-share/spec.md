# Feature Specification: Fix macOS Share Handler

**Feature Branch**: `002-fix-macos-share`
**Created**: 2026-04-22
**Status**: Draft
**Input**: User description: "Check the current code of ios and compare with macos. currently ios works when we share link and macos does not. BTW macos was never able to work so there is no point in history to look back. when I share a link, it opens the app on mac and thats it no logs, nothing. the actual thing does not work afterwards. also current example app is broken. you can wipe and recreate"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive shared link on macOS (Priority: P1)

A user shares a URL (e.g., from Safari) to the app via the macOS share sheet. The share extension captures the URL, stores it in shared UserDefaults, and opens the host app via the custom URL scheme. The host app receives the shared URL, extracts the data from UserDefaults, and delivers it to the Flutter app so it can be displayed or processed.

**Why this priority**: This is the core functionality — without it, the entire macOS share feature is non-functional. The iOS equivalent works correctly; macOS must achieve parity.

**Independent Test**: Share a URL from Safari to the example app on macOS and verify the URL content appears in the app UI. No other feature is needed for this test.

**Acceptance Scenarios**:

1. **Given** the app is not running, **When** the user shares a URL via the macOS share sheet, **Then** the app launches and the shared URL content is displayed in the Flutter app
2. **Given** the app is already running in the background, **When** the user shares a URL via the macOS share sheet, **Then** the app comes to the foreground and the shared URL content is displayed
3. **Given** the app is running and the share stream is being listened to, **When** a share event arrives, **Then** the `sharedMediaStream` emits a `SharedMedia` object with the URL in the `content` field

---

### User Story 2 - Receive shared text on macOS (Priority: P2)

A user shares text content (e.g., selected text from a webpage) to the app via the macOS share sheet. The text is captured and delivered to the Flutter app.

**Why this priority**: Text sharing is the second most common share action after URLs. It completes the basic share functionality.

**Independent Test**: Select text in any macOS app, share it to the example app, and verify the text appears.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** the user shares text via the macOS share sheet, **Then** the shared text content appears in the app
2. **Given** a multi-line text is shared, **When** the app receives it, **Then** all lines are preserved in the `content` field

---

### User Story 3 - Receive shared files on macOS (Priority: P3)

A user shares files (images, videos, documents) to the app via the macOS share sheet. Files are copied to the shared app group container and their paths are delivered to the Flutter app.

**Why this priority**: File sharing is important but less critical than text/URL sharing for a link handler. Ensures feature parity with iOS.

**Independent Test**: Share an image file from Finder to the example app and verify the file path and thumbnail appear.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** the user shares an image file, **Then** the file is copied to the app group container and the attachment path is delivered to Flutter
2. **Given** the user shares multiple files, **When** the app receives them, **Then** all file attachments are included in the `SharedMedia` object

---

### Edge Cases

- What happens when the app group container is not accessible (missing AppGroupId configuration)?
- What happens when the shared data in UserDefaults is corrupted or missing?
- What happens when the user shares content but the app is already in the process of launching?
- What happens when the share extension is triggered but there are no valid attachments?
- What happens when the custom URL scheme is not registered in the app's Info.plist?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The macOS share extension MUST capture shared URLs from the system share sheet and store them in shared UserDefaults
- **FR-002**: The macOS share extension MUST open the host app via the registered custom URL scheme after capturing shared data
- **FR-003**: The macOS host app MUST receive and process the custom URL scheme callback when opened by the share extension
- **FR-004**: The macOS host app MUST read shared data from the shared UserDefaults using the key from the URL query parameter
- **FR-005**: Shared data MUST be delivered to the Flutter app via the EventChannel stream (`sharedMediaStream`)
- **FR-006**: Shared data MUST be available via `getInitialSharedMedia()` when the app is cold-started by a share action
- **FR-007**: The macOS implementation MUST handle URL receipt through the correct macOS delegate mechanism, ensuring the callback is properly invoked when the app is opened via custom URL scheme
- **FR-008**: The example app MUST demonstrate the full share flow on macOS with clear visual feedback of received shared content
- **FR-009**: The example app MUST be buildable and runnable on macOS without errors
- **FR-010**: The macOS share extension MUST correctly derive the host app bundle identifier and app group ID
- **FR-011**: The macOS implementation MUST handle both cold-start (app not running) and warm-resume (app in background) scenarios

### Key Entities

- **SharedMedia**: The primary data object containing shared content (text, URLs) and file attachments. Passed from share extension to host app via JSON serialization in shared UserDefaults.
- **SharedAttachment**: A file attachment within SharedMedia, containing a file path and type classification (image, video, audio, file).
- **Custom URL Scheme**: The mechanism (`ShareMedia-<bundleId>://`) used to open the host app and pass the UserDefaults key for data retrieval.
- **App Group**: A shared container allowing the share extension and host app to exchange data via shared UserDefaults.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully share a URL from any macOS app to the example app and see the URL content displayed within 3 seconds of selecting the share action
- **SC-002**: Both cold-start and warm-resume share scenarios work correctly — the shared content is never lost regardless of whether the app was already running
- **SC-003**: The example app builds and runs on macOS without compilation or runtime errors
- **SC-004**: macOS share functionality achieves behavioral parity with the working iOS implementation — same data flow, same Dart API, same user experience

## Assumptions

- The share extension target, app group, and custom URL scheme are configured correctly in the app's Xcode project (these are app-level configuration, not plugin-level)
- The app developer follows the same setup pattern as iOS: creating a share extension target that inherits from the provided view controller class
- The macOS app group container and UserDefaults sharing work correctly when properly configured
- The existing iOS implementation serves as the reference for correct behavior
- The example app can be fully recreated from scratch without losing important functionality
