# Contracts: macOS Share Handler Platform Implementation

**Branch**: `001-publishing-scripts-macos`

## 1. Dart Platform Interface Contract (existing, from platform_interface package)

### ShareHandlerPlatform (abstract)

```
getInitialSharedMedia() → Future<SharedMedia?>
  - Returns the share that launched the app (one-time read)
  - Returns null if no initial share

recordSentMessage(conversationIdentifier, conversationName, conversationImageFilePath?, serviceName?) → Future<void>
  - Donates INSendMessageIntent for Siri conversation suggestions
  - Optional on macOS (lower priority)

resetInitialSharedMedia() → Future<void>
  - Clears initial media after consumption

sharedMediaStream → Stream<SharedMedia>
  - Continuous stream of shares received while app is running
  - Each event is a decoded SharedMedia
```

### ShareHandlerMacosPlatform (macOS implementation)

Must implement all above methods via:
- Pigeon `ShareHandlerApi` for request-response methods
- `EventChannel` named `wtf.zikzak.zikzak_share_handler/sharedMediaStream` for stream
- `registerWith()` static method that sets `ShareHandlerPlatform.instance`

## 2. Native Method Channel Contract

### Pigeon BasicMessageChannels

| Channel | Request | Response | Purpose |
|---|---|---|---|
| `dev.flutter.pigeon.ShareHandlerApi.getInitialSharedMedia` | null | SharedMedia? map or null | Get cold-start share |
| `dev.flutter.pigeon.ShareHandlerApi.recordSentMessage` | SharedMedia map | void | Donate intent |
| `dev.flutter.pigeon.ShareHandlerApi.resetInitialSharedMedia` | null | void | Clear initial state |

Custom codec with type IDs:
- 128 = SharedAttachment
- 129 = SharedMedia
- 130 = SharedMedia (reserved)

### EventChannel

| Channel | Event Type | Direction |
|---|---|---|
| `wtf.zikzak.zikzak_share_handler/sharedMediaStream` | SharedMedia map | Native → Dart |

## 3. Share Extension ↔ Main App Contract

### Communication via App Group

**Storage**: `UserDefaults(suiteName: "<appGroupId>")`

| Key | Type | Writer | Reader | When |
|---|---|---|---|---|
| `ShareKey` (configurable) | JSON Data | Share Extension | Main App Plugin | On every share |

**JSON format** (SharedMedia):
```json
{
  "attachments": [{"path": "/path/to/file", "type": 0}],
  "content": "https://example.com",
  "conversationIdentifier": null,
  "speakableGroupName": null,
  "serviceName": null,
  "senderIdentifier": null,
  "imageFilePath": null,
  "subject": null,
  "recipientIdentifiers": null
}
```

### Custom URL Scheme

**Pattern**: `ShareMedia-<hostAppBundleIdentifier>://<hostAppBundleIdentifier>?key=<storageKey>`

**Flow**:
1. Share Extension writes JSON to App Group UserDefaults under `<storageKey>`
2. Share Extension calls `NSWorkspace.shared.open(url)` with the custom scheme URL
3. Main app receives URL via `NSApplicationDelegate` methods
4. Plugin reads `<storageKey>` from URL query params
5. Plugin reads JSON from App Group UserDefaults
6. Plugin decodes to `SharedMedia`, sends to Flutter

## 4. Flutter Plugin Registration Contract (pubspec.yaml)

```yaml
flutter:
  plugin:
    implements: zikzak_share_handler
    platforms:
      macos:
        pluginClass: SwiftShareHandlerMacosPlatform
        dartPluginClass: ShareHandlerMacosPlatform
```

- `pluginClass`: Native Swift class conforming to `FlutterPlugin`
- `dartPluginClass`: Dart class with static `registerWith()` method

## 5. Podspec Contract

**Main podspec**: `zikzak_share_handler_macos.podspec`
- Source files: `Classes/**/*`
- Dependency: `FlutterMacOS`
- Platform: `osx, '10.11'` (minimum)
- Swift version: 5.0

**Models podspec**: `zikzak_share_handler_macos_models.podspec` (NEW)
- Source files: `Models/Classes/**/*`
- Contains: SharedModels.swift, ShareHandlerMacosViewController.swift
- No Flutter dependency (pure AppKit/Foundation)
- Used by both main app target and Share Extension target
