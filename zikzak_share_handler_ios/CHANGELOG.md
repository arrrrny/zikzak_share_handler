## 0.0.36 - 2026-06-14

* Prepare for publishing version 0.0.36
## 0.0.35 - 2026-06-13

* Prepare for publishing version 0.0.35
## 0.0.34 - 2026-06-09

- **SPM support**: Added Swift Package Manager support with `Package.swift`
- **Pure Swift**: Removed Objective-C plugin shim (`ShareHandlerIosPlugin.h/.m`)
- **Gray overlay fix**: `completeRequest` called from `openURL` completion handler so source app dismisses cleanly after host app switch
- **Cross-module fix**: `viewDidLoad` and `viewDidAppear` changed to `open override` for subclassing outside the module
- **Foundation import**: Added `import Foundation` to `SharedModels.swift` for SPM module isolation
- **Restructured**: Source files moved to `Sources/zikzak_share_handler_ios/` and `Sources/zikzak_share_handler_ios_models/`
- **Podspecs**: Updated to point to new SPM-compatible paths
- **Renamed**: `SwiftShareHandlerIosPlatform` → `ShareHandlerIosPlatform` (matches pubspec `pluginClass`)
- **Gitignore**: Added `.build/` and `.swiftpm/`

## 0.0.31 - 2026-04-21

- fix: UIApplication.openURL is deprecated

# 0.0.17

Fix bug in event method

# 0.0.16

Updated podspec to match correct version of the library.

# 0.0.15

Fix for IOS 18 not opening due to UIApplication.openURL is deprecated Thx to dbrpci

# 0.0.14

Fix for iOS 14 compile error when recording a sent message with INOutgoingMessageType

# 0.0.13

Fix for iOS 14 deprecation when recording a sent message with INSendMessageIntent

# 0.0.12

Don't show default share modal and go straight to redirect to flutter app

# 0.0.11

Support handling a shared contact card (vcf)

# 0.0.10

Update to allow for newer dart sdk version

# 0.0.9

Fix for non public methods in inherited viewcontroller

# 0.0.8

Setup podspecs and dependencies better

# 0.0.7

Put inheritable view controller into sub pod library so the ShareViewController can simply inherit it, rather than copy in code

# 0.0.6

Fix to decode file paths in case of platform encoded paths
Added documentation to model attributes

# 0.0.5

Added support for handling airdropped files

# 0.0.4

Fix for channel sometimes receiving full SharedMedia object rather than map

# 0.0.3

Updated platform interface dependency

# 0.0.2

Updated License
Updated platform interface dependency

# 0.0.1

Initial release of this plugin.
