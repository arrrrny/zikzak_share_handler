# Quickstart: macOS Share Handler Implementation

**Branch**: `001-publishing-scripts-macos`

## Prerequisites

- Flutter SDK with macOS desktop support enabled
- Xcode with macOS SDK
- CocoaPods installed

## Development Setup

### 1. Enable macOS on the main package

Uncomment macOS in `zikzak_share_handler/pubspec.yaml`:
- `macos: default_package: zikzak_share_handler_macos` under plugin platforms
- `zikzak_share_handler_macos: path: ../zikzak_share_handler_macos` under dependencies

### 2. Fix macOS pubspec.yaml

In `zikzak_share_handler_macos/pubspec.yaml`:
- Change `platforms: ios:` to `platforms: macos:`
- Add `dartPluginClass: ShareHandlerMacosPlatform`
- Add `implements: zikzak_share_handler`
- Switch dependency from versioned to path for dev

### 3. Fix macOS podspec

In `zikzak_share_handler_macos/macos/zikzak_share_handler.podspec`:
- Rename to `zikzak_share_handler_macos.podspec`
- Update `s.name` to `zikzak_share_handler_macos`

### 4. Build and test cycle

```bash
cd zikzak_share_handler/example
flutter pub get
flutter run -d macos
```

## Testing URL Sharing

1. Build and run the example app on macOS
2. Open Safari, navigate to any page
3. Use File → Share → select the example app
4. Verify the shared URL prints in the console

## Publishing Scripts Usage

```bash
# 1. Prepare for publish (creates branch, updates versions)
./scripts/prepare_for_publish.sh 1.0.0

# 2. Publish to pub.dev
./scripts/publish.sh

# 3. After publish, restore dev setup
./scripts/restore_dev_setup.sh

# OR revert everything
./scripts/revert_publish_changes.sh

# OR merge to master and push
./scripts/push_to_master.sh
```
