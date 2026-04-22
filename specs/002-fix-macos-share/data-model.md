# Data Model: Fix macOS Share Handler

**Feature**: 002-fix-macos-share
**Date**: 2026-04-22

## Entities

### SharedMedia

The primary payload passed from the share extension to the host app.

| Field | Type | Description |
|---|---|---|
| content | String? | Shared text or URL content (multiple items joined with newline) |
| attachments | List\<SharedAttachment\>? | File attachments (images, videos, documents) |
| conversationIdentifier | String? | Conversation ID (from intent system) |
| subject | String? | Subject of shared content |
| speakableGroupName | String? | Spoken group name (iOS intent) |
| serviceName | String? | Service name (iOS intent) |
| senderIdentifier | String? | Sender contact ID (iOS intent) |
| imageFilePath | String? | Image file path for intent donation |

**Serialization**: JSON via `Codable` conformance. Stored in shared `UserDefaults` under a key referenced in the custom URL scheme query parameter.

### SharedAttachment

A single file attachment within a SharedMedia.

| Field | Type | Description |
|---|---|---|
| path | String | Absolute file path in the shared app group container |
| type | SharedAttachmentType | Classification: image, video, audio, or file |

**Validation**: Path must be an absolute filesystem path (no `file://` prefix after processing).

### SharedAttachmentType (enum)

- `image` — Image files
- `video` — Video files
- `audio` — Audio files
- `file` — Generic files

### Custom URL Scheme

Format: `ShareMedia-<hostAppBundleId>://<hostAppBundleId>?key=<UserDefaultsKey>`

| Component | Description |
|---|---|
| Scheme | `ShareMedia-<bundleId>` |
| Host | `<bundleId>` |
| Query param `key` | UserDefaults key where SharedMedia JSON is stored |

### App Group

Identifier: `group.<hostAppBundleId>` (default) or custom ID via `AppGroupId` Info.plist key.

Used for:
1. Shared `UserDefaults(suiteName:)` — JSON data exchange
2. Shared file container — attachment file copying

## Data Flow

```
Share Extension                          Host App
─────────────                            ─────────
1. Receive NSExtensionItem attachments
2. Process by UTType:
   - URL → append to content
   - Text → append to content
   - FileURL → copy to container, create SharedAttachment
3. Create SharedMedia object
4. Encode to JSON
5. Store in UserDefaults(suiteName: appGroupId)[key]
6. Open URL: ShareMedia-<id>://<id>?key=<key>
                                         7. Receive URL via handleOpenURLs
                                         8. Read JSON from UserDefaults
                                         9. Decode to SharedMedia
                                         10. Resolve attachment paths
                                         11. Store as initialMedia (if cold start)
                                         12. Push to EventChannel eventSink
                                                  │
                                                  ▼
                                         13. Dart sharedMediaStream emits SharedMedia
```

## State Transitions

### SharedMedia lifecycle in host app

```
[Incoming URL] → handleUrl() → latestMedia (always updated)
                                initialMedia (only on cold start)
                                     │
                                     ▼
                              eventSink?.(toDictionary())
                                     │
                                     ▼
                              Dart EventChannel stream
```

### Initial media retrieval

```
getInitialSharedMedia() → returns initialMedia → null after resetInitialSharedMedia()
```
