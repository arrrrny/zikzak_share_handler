# Data Model: Publishing Scripts and macOS Platform Support

**Branch**: `001-publishing-scripts-macos`

## Entities

### SharedMedia (existing, shared across all platforms)

Represents a single shared content payload flowing from native to Flutter.

| Field | Type | Description |
|---|---|---|
| attachments | `List<SharedAttachment>?` | File attachments with paths and types |
| conversationIdentifier | `String?` | Conversation ID (from INSendMessageIntent) |
| content | `String?` | Shared text or URL content |
| speakableGroupName | `String?` | Contact/group name |
| serviceName | `String?` | Service that sent the content |
| senderIdentifier | `String?` | Sender contact ID |
| imageFilePath | `String?` | Sender avatar file path |
| subject | `String?` | Subject line |

**Encoding**: Pigeon `BasicMessageChannel` with custom codec (type IDs 128-130) OR JSON via `UserDefaults(suiteName:)` for Share Extension communication.

**State transitions**:
1. Created in Share Extension from `NSExtensionItem` input
2. Serialized to JSON → stored in App Group `UserDefaults`
3. Deserialized in main app plugin → sent to Flutter via `EventChannel` or `getInitialSharedMedia()`
4. Consumed by Flutter app via stream or one-time read

### SharedAttachment (existing, shared across all platforms)

Represents a single file attachment within a shared media payload.

| Field | Type | Description |
|---|---|---|
| path | `String` | File path on device (URI-decoded on iOS/macOS) |
| type | `SharedAttachmentType` | Enum: image(0), video(1), audio(2), file(3) |

**Validation**: Path must be non-empty. Type must be valid enum value (0-3).

**Platform behavior**:
- iOS/macOS: `path` is URI-decoded (`Uri.decodeFull`)
- Android/other: `path` is used as-is

### ShareHandlerMacosPlatform (new)

The macOS Dart-side platform implementation.

| Responsibility | Method |
|---|---|
| Registration | `registerWith()` → sets `ShareHandlerPlatform.instance` |
| Get initial share | `getInitialSharedMedia()` → Pigeon API call |
| Record message | `recordSentMessage(...)` → Pigeon API call |
| Reset initial | `resetInitialSharedMedia()` → Pigeon API call |
| Stream | `sharedMediaStream` → EventChannel broadcast |

**Relationships**: Extends `ShareHandlerPlatform` (from platform_interface). Delegates to native via `ShareHandlerApi` (Pigeon) and `EventChannel`.

### SwiftShareHandlerMacosPlatform (new, native)

The macOS native Swift plugin.

| Responsibility | Method |
|---|---|
| Flutter registration | `register(with:)` → sets up channels, Pigeon API, EventChannel, app delegate |
| URL handling | `application(_:openFile:)`, `application(_:openUrls:)` |
| Initial URL (cold start) | `applicationWillFinishLaunching` or similar |
| URL dispatch | `handleUrl(url:setInitialData:)` → reads App Group, decodes SharedMedia |

**Relationships**: Conforms to `FlutterPlugin`, `FlutterStreamHandler`, `NSApplicationDelegate`. Singleton pattern (same as iOS).

### ShareHandlerMacosViewController (new, native Share Extension)

The macOS Share Extension view controller.

| Responsibility | Method |
|---|---|
| Load input | `loadInputItems()` → iterate `NSExtensionContext.inputItems` |
| URL extraction | Parse URL-type `NSItemProvider` items |
| File extraction | Parse file-type `NSItemProvider` items (future phase) |
| Store & redirect | `redirectToHostApp()` → write to App Group, open custom URL scheme |

**Relationships**: Subclass of `NSViewController`. Uses `SharedMedia`/`SharedAttachment` models from shared pod.

### Federated Package Dependency Graph

```
zikzak_share_handler_platform_interface (base)
  ↑ depends on
  ├── zikzak_share_handler_android
  ├── zikzak_share_handler_ios
  ├── zikzak_share_handler_macos (NEW - to implement)
  ├── zikzak_share_handler_web
  ├── zikzak_share_handler_windows
  └── zikzak_share_handler_linux
  
zikzak_share_handler (main/app-facing)
  depends on ALL of the above
```

### Publishing Script Configuration

| Script | Input | Output |
|---|---|---|
| `prepare_for_publish.sh` | Version number | Publish branch with versioned deps |
| `publish.sh` | (none) | Published packages on pub.dev |
| `restore_dev_setup.sh` | (none) | Path dependencies restored |
| `revert_publish_changes.sh` | (none) | Back on main branch |
| `push_to_master.sh` | (none) | Merged to master with tag |
