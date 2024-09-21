#import "ShareHandlerIosPlugin.h"
#if __has_include(<zikzak_share_handler_ios/zikzak_share_handler_ios-Swift.h>)
#import <zikzak_share_handler_ios/zikzak_share_handler_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "zikzak_share_handler_ios-Swift.h"
#endif

@implementation ShareHandlerIosPlatform
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftShareHandlerIosPlatform registerWithRegistrar:registrar];
}
@end
