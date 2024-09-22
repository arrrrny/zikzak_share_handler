# Share Handler plugin for Flutter

A Flutter plugin for iOS and Android to handle incoming shared text/media, as well as add share to suggestions/shortcuts.

This package is the fork of the package [share_handler](https://pub.dev/packages/share_handler)

## Installation

First, add `zikzak_share_handler` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

### iOS

#### Xcode 16 IOS 18 IMPORTANT!

Before running pod install make sure to

Convert Share Extension to Group
![Group Share Extension](setup_images/convert_to_group.png)

Move Thin Library to the bottom of the build phase

![Arrange Build Phases](setup_images/thin_library.png)

Update the ios/Runner/Release.xcconfig file as below:

```bash
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "Generated.xcconfig"
```

Update the ios/Runner/Debug.xcconfig file as below:

```bash
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "Generated.xcconfig"
```


1. Add the following to `<project root>/ios/Runner/Info.plist`. It registers your app to open via a deep link that will be launched from the Share Extension. Also, for sharing photos, you will need access to the photo library.

```xml
<!-- Add for zikzak_share_handler start -->
<!-- The 'NSUserActivityTypes' key is only needed if you plan to use the recordSentMessage API allowing for conversations to show up as direct share suggestions -->
<key>NSUserActivityTypes</key>
<array>
    <string>INSendMessageIntent</string>
</array>

<!-- Uncomment below lines if you want to use a custom group id rather than the default. Set it in Build Settings -> User-Defined -->
<!-- <key>AppGroupId</key>
<string>$(CUSTOM_GROUP_ID)</string> -->

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
</array>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photos can be shared to and used in this app</string>

<!-- Optional: Add/Customize for AirDrop support -->
<key>LSSupportsOpeningDocumentsInPlace</key>
<string>No</string>
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>ShareHandler</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.file-url</string>
            <string>public.image</string>
            <string>public.text</string>
            <string>public.movie</string>
            <string>public.url</string>
            <string>public.data</string>
        </array>
    </dict>
</array>

<!-- Add for zikzak_share_handler end -->
```

2. Create Share Extension
   - In Xcode, go to the menu and select File->New->Target and choose "Share Extension"
   - Give it the name "ShareExtension" and save
3. Make the following edits to `<project root>/ios/ShareExtension/Info.plist`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Uncomment below lines if you want to use a custom group id rather than the default. Set it in Build Settings -> User-Defined -->
    <!-- <key>AppGroupId</key>
    <string>$(CUSTOM_GROUP_ID)</string> -->

    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <!-- Add supported message intent if you support sharing to a specific conversation - start -->
            <key>IntentsSupported</key>
            <array>
                <string>INSendMessageIntent</string>
            </array>
            <!-- Add supported message intent if you support sharing to a specific conversation (registered via the recordSentMessage api call) - end -->
            <key>NSExtensionActivationRule</key>
            <!-- Comment or delete the TRUEPREDICATE NSExtensionActivationRule that only works in development mode -->
            <!-- <string>TRUEPREDICATE</string> -->
            <!-- Add a new NSExtensionActivationRule. The rule below will allow sharing one or more file of any type, url, or text content, You can modify these rules to your liking for which types of share content, as well as how many your app can handle -->
            <string>SUBQUERY (
                extensionItems,
                $extensionItem,
                SUBQUERY (
                    $extensionItem.attachments,
                    $attachment,
                    (
                        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.file-url"
                        || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.image"
                        || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.text"
                        || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.movie"
                        || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url"
                    )
                ).@count > 0
            ).@count > 0
	    </string>
	    <key>PHSupportedMediaTypes</key>
	    <array>
	        <string>Video</string>
	        <string>Image</string>
	    </array>
        </dict>
        <key>NSExtensionMainStoryboard</key>
        <string>MainInterface</string>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
    </dict>
</dict>
</plist>
```

4. Add a group identifier to both the Runner and ShareExtension Targets
   - In Xcode, select Runner -> Targets -> Runner -> Signing & Capabilities
   - Click the '+' button and select 'App Groups'
   - Add a new group (default is your bundle identifier prefixed by 'group.'. ex. 'group.wtf.zikzak')
   - Repeat those 3 steps inside of the 'ShareExtension' target adding/selecting the same group id
5. (Optional) If you made a custom group identifier that isn't your bundle identifier prefixed by 'group.', make sure to add a custom build setting variable that is referenced in your shareExtension's info.plist file.
   - Go to Targets -> ShareExtension -> Build Settings
   - Click the '+' icon and select 'Add User-Defined Setting'
   - Give it the key 'CUSTOM_GROUP_ID' and the value of the app group identifier that you gave to both targets in the previous step
   - Repeat the above 2 steps for the 'Runner' target
6. Add the following code inside `<project root>/ios/Podfile` within the `target 'Runner' do` block, and then run `pod install` inside of `<project root>/ios`.

```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # zikzak_share_handler addition start
  target 'ShareExtension' do
    inherit! :search_paths
    pod "zikzak_share_handler_ios_models", :path => ".symlinks/plugins/zikzak_share_handler_ios/ios/Models"
  end
  # zikzak_share_handler addition end
end
```

7. In Xcode, replace the contents of ShareExtension/ShareViewController.swift with the following code. The share extension doesn't launch a UI of its own, instead it serializes the shared content/media and saves it to the groups shared preferences, then opens a deep link into the full app so your flutter/dart code can then read the serialized data and handle it accordingly.

```swift
import zikzak_share_handler_ios_models

class ShareViewController: ShareHandlerIosViewController {}
```

### Android

1. Edit your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml` and add/uncomment the intent filters and meta data that you want to support:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
.....
 >
 <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

  <application
        android:name="io.flutter.app.FlutterApplication"
        ...
        >

    <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

             <!--TODO: Add this filter if you want to handle shared text-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle shared images-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle shared videos-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="video/*" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="video/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle any type of file-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="*/*" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="*/*" />
            </intent-filter>

            <!-- TODO: (Optional) Add these meta-data tags if you want to support sharing to a specific target/conversation/shortcut (via the recordSentMessage api) -->
            <meta-data
                android:name="android.service.chooser.chooser_target_service"
                android:value="androidx.sharetarget.ChooserTargetServiceCompat" />
            <meta-data
                android:name="android.app.shortcuts"
                android:resource="@xml/share_targets" />
      </activity>

  </application>
</manifest>
```

2. (Optional) If you want to prevent incoming shares from opening a new activity each time, add the attribute `android:launchMode="singleTask"` to your MainActivity intent inside your AndroidManifest.xml file.
3. (Optional) Add required file to support share suggestions/shortcuts in to your app.
   - Create the file `<project root>/android/app/src/main/res/xml/share_targets.xml` with the following contents, replacing `{your.package.identifier}` with your package identifier (ex. wtf.zikzak.zikzak_share_handler_android_example):

```xml
<?xml version="1.0" encoding="utf-8"?>
<shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
    <share-target android:targetClass="{your.package.identifier}.MainActivity">
        <data android:mimeType="*/*" />
        <category android:name="{your.package.identifier}.dynamic_share_target" />
    </share-target>
</shortcuts>
```

## Example

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:zikzak_share_handler/zikzak_share_handler.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  SharedMedia? media;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        this.media = media;
      });
    });
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Share Handler'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Text("Shared to conversation identifier: ${media?.conversationIdentifier}"),
              const SizedBox(height: 10),
              Text("Shared text: ${media?.content}"),
              const SizedBox(height: 10),
              Text("Shared files: ${media?.attachments?.length}"),
              ...(media?.attachments ?? []).map((attachment) {
                final path = attachment?.path;
                if (path != null && attachment?.type == SharedAttachmentType.image) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ShareHandlerPlatform.instance.recordSentMessage(
                            conversationIdentifier: "custom-conversation-identifier",
                            conversationName: "John Doe",
                            conversationImageFilePath: path,
                            serviceName: "custom-service-name",
                          );
                        },
                        child: const Text("Record message"),
                      ),
                      const SizedBox(height: 10),
                      Image.file(File(path)),
                    ],
                  );
                } else {
                  return Text("${attachment?.type} Attachment: ${attachment?.path}");
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Attributions
This package is the fork of the share_handler package https://pub.dev/packages/share_handler In the emergency case of the original package not working on IOS, I decided to  fork it and make the necessary changes to make it work on IOS. The original package is maintained by  https://github.com/arrrrny

Special thanks to the contributors of the receive_sharing_intent package from which I garnered a lot of code/logic and built thereon - https://github.com/KasemJaffer/receive_sharing_intent. It seemed to not be maintained and not responsive to issues/feature requests, hence the new package.
