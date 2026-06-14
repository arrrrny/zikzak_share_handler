## 0.0.36 - 2026-06-14

* Prepare for publishing version 0.0.36
## 0.0.35 - 2026-06-13

* Prepare for publishing version 0.0.35
## 0.0.34 - 2026-06-09

- **iOS & macOS**: Added Swift Package Manager (SPM) support with proper `Package.swift` setup
- **iOS & macOS**: Removed Objective-C plugin shim — migrated to pure Swift
- **iOS & macOS**: Fixed share extension gray overlay / stuck dimming overlay on source app
  - `completeRequest` is now called from the `openURL` completion handler
  - The source app only receives the dismiss signal after the host app has launched
- **iOS & macOS**: Updated `viewDidLoad` to `open override` for proper cross-module subclassing
- **iOS & macOS**: Added missing `import Foundation` for SPM module isolation
- **iOS & macOS**: Restructured source layout into SPM convention (`Sources/<target>/`)
- **iOS & macOS**: Updated podspecs to point to new SPM-compatible source paths

## 0.0.31 - 2026-04-21

- fix: UIApplication.openURL is deprecated

# 0.0.30

Updated README

# 0.0.29

Updated IOS setup instructions

# 0.0.28

Updated IOS setup instructions

# 0.0.27

Updated IOS setup instructions

# 0.0.26

Updated IOS setup instructions

# 0.0.25

Updated package dependencies

# 0.0.24

Updated podspec to match correct version of the library.

# 0.0.23

Updated ReadME

# 0.0.22

IOS -Fixed IOS 18 not working due to UIApplication.openURL is deprecated, bumped compileSDK to 34

# 0.0.21

iOS - Fix for iOS 14 compile error when recording a sent message with INOutgoingMessageType
Android - Add namespace to allow for Gradle 8

# 0.0.20

iOS - Fix for iOS 14 deprecation when recording a sent message with INSendMessageIntent

# 0.0.19

iOS - Don't show default share modal and go straight to redirect to flutter app

# 0.0.18

Support handling a shared contact card (vcf) on iOS

# 0.0.17

Fix problems receiving files on Android "Android/Files/Recent"
Fix problem with special characters in filename
Update to allow for newer dart sdk version

# 0.0.16

Fix for non public methods in inherited viewcontroller for iOS

# 0.0.15

Updated Readme for custom group id for the runner target

# 0.0.14

Updated readme to comment out custom group id in info plists by default.

# 0.0.13

Setup podspecs and dependencies better for ios

# 0.0.12

Put inheritable view controller into sub pod library so the ShareViewController can simply inherit it, rather than copy in code. Adjusted README accordingly.

# 0.0.11

Fix for receiving shared .txt files on Android

# 0.0.10

Update example to use the latest README instructions

# 0.0.9

Fix for sharing file from safari. Updated readme accordingly.

# 0.0.8

Fixes and updates for README

# 0.0.7

Fixes and updates for README

# 0.0.6

Fix to decode file paths in case of platform encoded paths
Added documentation to model attributes

# 0.0.5

Added support for handling airdropped files

# 0.0.4

Fix for channel sometimes receiving full SharedMedia object rather than map

# 0.0.3

Fix for error getting initial media

# 0.0.2

Initial release of this plugin.
