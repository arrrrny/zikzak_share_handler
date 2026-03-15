# UISceneDelegate Migration Guide

This plugin has been updated to support iOS 13+ UISceneDelegate lifecycle, as required by Flutter's [UISceneDelegate adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) breaking change.

## What Changed

The plugin now supports both the legacy AppDelegate-only pattern and the modern UISceneDelegate pattern for handling URLs and shared content. This ensures compatibility with:

- iOS 13+ scene-based lifecycle
- Future iOS SDK requirements (iOS 26+ requires UIScene support)
- Flutter 3.41+ which makes UISceneDelegate the default

## Migration Steps for Your App

If you're using this plugin in your iOS app, follow these steps to adopt UISceneDelegate:

### 1. Create SceneDelegate.swift

Create a new file `ios/Runner/SceneDelegate.swift` in your Flutter project:

```swift
import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: FlutterSceneDelegate {

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        // Handle any URLs that were used to open the app
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            _ = scene(scene, openURLContexts: connectionOptions.urlContexts)
        }

        // Handle user activities (for universal links and handoff)
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            _ = scene(scene, continue: userActivity)
        }
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        return super.scene(scene, openURLContexts: URLContexts)
    }

    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        return super.scene(scene, continue: userActivity)
    }
}
```

### 2. Update AppDelegate.swift

Update your `ios/Runner/AppDelegate.swift` to support scene configuration:

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: UISceneSession Lifecycle

  @available(iOS 13.0, *)
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }

  @available(iOS 13.0, *)
  override func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
  }
}
```

### 3. Update Info.plist

Add the UISceneConfiguration to your `ios/Runner/Info.plist` file, inside the main `<dict>` tag:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

### 4. Add SceneDelegate.swift to Xcode Project

If you're manually managing your Xcode project:

1. Open `ios/Runner.xcodeproj` in Xcode
2. Right-click on the `Runner` folder
3. Select "Add Files to Runner..."
4. Select `SceneDelegate.swift`
5. Ensure "Copy items if needed" is checked
6. Ensure the "Runner" target is selected

Or let Flutter CLI automatically add it during your next build.

## Backward Compatibility

The plugin maintains full backward compatibility:

- **iOS 12 and earlier**: Uses legacy AppDelegate methods (`application(_:open:options:)`, `application(_:continue:restorationHandler:)`)
- **iOS 13+**: Uses both AppDelegate and UISceneDelegate methods, with scenes taking priority when available

The plugin automatically detects the iOS version and uses the appropriate delegate methods.

## Testing

After migration, test the following scenarios:

1. **Cold Start with Shared Content**: Close the app completely, then share content from another app
2. **Warm Start with Shared Content**: Leave the app in background, then share content
3. **Multiple Share Actions**: Share multiple items in quick succession
4. **Universal Links**: Test any universal links your app handles
5. **Custom URL Schemes**: Test the `ShareMedia-` URL scheme

## Plugin Implementation Details

The plugin now:

- Registers as both `FlutterAppDelegate` and `FlutterSceneDelegate`
- Implements scene-based URL handling methods:
  - `scene(_:openURLContexts:)` - replaces `application(_:open:options:)`
  - `scene(_:continue:)` - replaces `application(_:continue:restorationHandler:)`
  - `scene(_:willConnectTo:options:)` - replaces `application(_:didFinishLaunchingWithOptions:)` for scene launches
- Maintains AppDelegate methods for backward compatibility

## Troubleshooting

### App crashes on iOS 13+ with "Could not find UISceneDelegate"

Ensure you've:
1. Created the `SceneDelegate.swift` file
2. Added it to your Xcode project
3. Updated `Info.plist` with UIApplicationSceneManifest

### Shared content not being received

1. Check that your custom URL scheme is still registered in `Info.plist`
2. Verify the Share Extension target is properly configured
3. Ensure app groups are correctly set up
4. Check device logs for any URL handling errors

### Build errors about SceneDelegate

If using an older Xcode/iOS deployment target:
- Minimum iOS deployment target should be iOS 13.0 or later for scene support
- Or use `@available(iOS 13.0, *)` guards around scene code

## Additional Resources

- [Flutter UISceneDelegate Migration Guide](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)
- [Apple UISceneDelegate Documentation](https://developer.apple.com/documentation/uikit/uiscenedelegate)
- [Apple Scene-Based Lifecycle Guide](https://developer.apple.com/documentation/uikit/app_and_environment/scenes)

## Support

If you encounter issues with the migration, please:
1. Check the example app in this repository for a working implementation
2. Review the troubleshooting section above
3. File an issue on GitHub with details about your setup and error messages
